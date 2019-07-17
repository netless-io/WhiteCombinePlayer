//
//  WhiteCombinePlayer.m
//  WhiteSDK
//
//  Created by yleaf on 2019/7/11.
//

#import "WhiteCombinePlayer.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, PauseReason) {
    PauseReasonNone,
    PauseReasonVideoPause,
    PauseReasonRePlayerBuffering,
};

#ifdef DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define DLog(...)
#endif

@interface WhiteCombinePlayer ()
@property (nonatomic, strong, readwrite) AVPlayer *videoPlayer;
@property (nonatomic, strong, readwrite) WhitePlayer *replayer;

@property (nonatomic, assign, getter=isRouteChangedWhilePlaying) BOOL routeChangedWhilePlaying;
@property (nonatomic, assign, getter=isInterruptedWhilePlaying) BOOL interruptedWhilePlaying;

@property (nonatomic, assign, getter=isReplayerBufferring) BOOL replayerBufferring;

@property (nonatomic, assign) PauseReason pauseReson;

@end

@implementation WhiteCombinePlayer

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverWithPlayItem:self.videoPlayer.currentItem];
}

- (instancetype)initWithVideoPlayer:(AVPlayer *)player replayer:(WhitePlayer *)replayer
{
    if (self = [super init]) {
        _videoPlayer = player;
        _replayer = replayer;
        _replayerBufferring = YES;
    }
    [self setup];
    return self;
}

- (instancetype)initWithVideoUrl:(NSURL *)videoUrl replayer:(WhitePlayer *)replayer
{
    AVPlayer *videoPlayer = [AVPlayer playerWithURL:videoUrl];
    return [self initWithVideoPlayer:videoPlayer replayer:replayer];
}

- (void)setup
{
    [self registerAudioSessionNotification];
    [self.videoPlayer addObserver:self forKeyPath:kRateKey options:0 context:nil];
    [self.videoPlayer addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

#pragma mark - Private

/**
 并非真正播放，包含缓冲可能性

 @return video 是否处于想要播放的状态
 */
- (BOOL)videoDesireToPlay
{
    return self.videoPlayer.rate != 0;
}

- (BOOL)isLoaded:(NSArray<NSValue *> *)timeranges
{
    if ([timeranges count] == 0) {
        return NO;
    }
    CMTimeRange timerange = [[timeranges firstObject] CMTimeRangeValue];
    CMTime bufferdTime = CMTimeAdd(timerange.start, timerange.duration);
    CMTime milestone = CMTimeAdd(self.videoPlayer.currentTime, CMTimeMakeWithSeconds(5.0f, timerange.duration.timescale));
    
    if (CMTIME_COMPARE_INLINE(bufferdTime , >, milestone) && self.videoPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay && !self.isInterruptedWhilePlaying && !self.isRouteChangedWhilePlaying) {
        return YES;
    }
    return NO;
}

- (BOOL)hasEnoughBuffer
{
    return self.videoPlayer.currentItem.isPlaybackLikelyToKeepUp;
}

#pragma mark - Notification

- (void)registerAudioSessionNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
    
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interruption:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(routeChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
#endif
}

#pragma mark - Notification

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    if (notification.object == self.videoPlayer.currentItem && [self.delegate respondsToSelector:@selector(videoPlayerDidFinish)]) {
        [self.delegate videoPlayerDidFinish];
    }
}

- (void)interruption:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interruptionType = [interuptionDict[AVAudioSessionInterruptionTypeKey] integerValue];
    
    if (interruptionType == AVAudioSessionInterruptionTypeBegan && [self videoDesireToPlay]) {
        self.interruptedWhilePlaying = YES;
        [self pause];
    } else if (interruptionType == AVAudioSessionInterruptionTypeEnded && self.isInterruptedWhilePlaying) {
        self.interruptedWhilePlaying = NO;
        NSInteger resume = [interuptionDict[AVAudioSessionInterruptionOptionKey] integerValue];
        if (resume == AVAudioSessionInterruptionOptionShouldResume) {
            [self play];
        }
    }
}

- (void)routeChange:(NSNotification *)notification
{
    NSDictionary *routeChangeDict = notification.userInfo;
    NSInteger routeChangeType = [routeChangeDict[AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeType == AVAudioSessionRouteChangeReasonOldDeviceUnavailable && [self videoDesireToPlay]) {
        self.routeChangedWhilePlaying = YES;
        [self pause];
    } else if (routeChangeType == AVAudioSessionRouteChangeReasonNewDeviceAvailable && self.isRouteChangedWhilePlaying) {
        self.routeChangedWhilePlaying = NO;
        [self play];
    }
}

#pragma mark - KVO
static NSString * const kRateKey = @"rate";
static NSString * const kCurrentItemKey = @"currentItem";
static NSString * const kStatusKey = @"status";
static NSString * const kPlaybackBufferEmptyKey = @"playbackBufferEmpty";
static NSString * const kPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const kLoadedTimeRangesKey = @"loadedTimeRanges";

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {

    if (object != self.videoPlayer.currentItem && object != self.videoPlayer) {
        return;
    }
    
    if (object == self.videoPlayer && [keyPath isEqualToString:kStatusKey]) {
        if (self.videoPlayer.status == AVPlayerStatusFailed && [self.delegate respondsToSelector:@selector(combinePlayerError:)]) {
            [self.delegate combinePlayerError:self.videoPlayer.error];
        }
    } else if (object == self.videoPlayer && [keyPath isEqualToString:kCurrentItemKey]) {
        // 防止主动替换 CurrentItem，理论上单个Video 不会进行替换
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        AVPlayerItem *lastPlayerItem = [change objectForKey:NSKeyValueChangeOldKey];
        if (lastPlayerItem != (id)[NSNull null]) {
            @try {
                [self removeObserverWithPlayItem:lastPlayerItem];
            } @catch(id anException) {
                //do nothing, obviously it wasn't attached because an exception was thrown
            }
        }
        if (newPlayerItem != (id)[NSNull null]) {
            [self addObserverWithPlayItem:newPlayerItem];
        }

    } else if ([keyPath isEqualToString:kRateKey]) {
        if ([self.delegate respondsToSelector:@selector(combinePlayerPlayStateChange:)]) {
            [self.delegate combinePlayerPlayStateChange:[self videoDesireToPlay]];
        }
    } else if ([keyPath isEqualToString:kStatusKey]) {
        if (self.videoPlayer.currentItem.status == AVPlayerItemStatusFailed && [self.delegate respondsToSelector:@selector(combinePlayerError:)]) {
            [self.delegate combinePlayerError:self.videoPlayer.currentItem.error];
        }
    } else if ([keyPath isEqualToString:kPlaybackBufferEmptyKey]) {
        if (self.videoPlayer.currentItem.isPlaybackBufferEmpty) {
            [self startBuffering];
        }
    } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUpKey]) {
        if (self.videoPlayer.currentItem.isPlaybackLikelyToKeepUp) {
            [self endBuffering];
        }
    } else if ([keyPath isEqualToString:kLoadedTimeRangesKey]) {
        NSArray *timeRanges = (NSArray *)change[NSKeyValueChangeNewKey];
        if ([self.delegate respondsToSelector:@selector(loadedTimeRangeChange:)]) {
            [self.delegate loadedTimeRangeChange:timeRanges];
        }
    }
}

// 推荐使用 KVOController 做 KVO 监听
- (void)addObserverWithPlayItem:(AVPlayerItem *)item
{
    [item addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kLoadedTimeRangesKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kPlaybackBufferEmptyKey options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverWithPlayItem:(AVPlayerItem *)item
{
    [item removeObserver:self forKeyPath:kStatusKey];
    [item removeObserver:self forKeyPath:kLoadedTimeRangesKey];
    [item removeObserver:self forKeyPath:kPlaybackBufferEmptyKey];
    [item removeObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey];
}

#pragma mark - Buffering
- (void)startBuffering
{
    if ([self.delegate respondsToSelector:@selector(combinePlayerStartBuffering)]) {
        [self.delegate combinePlayerStartBuffering];
    }
    DLog(@"");
    
    // 直接暂停 replayer 播放
    // replayer 加载 bufferring 的行为，一旦开始，不会停止。
    [self pauseReplayer];
}

- (void)endBuffering
{
    if ([self.delegate respondsToSelector:@selector(combinePlayerEndBuffering)]) {
        [self.delegate combinePlayerEndBuffering];
    }
    
/*
 1. replayer 未缓存完成；暂停 video 播放(初始化后，先执行 replayer 的 seek 后，该情况发生概率不大)
 2. replayer 缓存完成，之前 video 已经暂停；整体播放
 3. 其他情况，直接播放 replayer
 */
    
    if (self.isReplayerBufferring) {
        DLog(@"isReplayerBufferring");
        [self pauseForReplayerBuffing];
    } else if (self.pauseReson == PauseReasonRePlayerBuffering) {
        DLog(@"PauseReasonRePlayerBuffering");
        [self play];
    } else {
        DLog(@"playReplayer");
        [self playReplayer];
    }
}

#pragma mark - Play Control

- (void)playReplayer
{
    [self.replayer play];
}

- (void)pauseReplayer
{
    [self.replayer pause];
}

#pragma mark - Public Methods
- (void)play
{
    self.pauseReson = PauseReasonNone;
    [self.videoPlayer play];
    self.interruptedWhilePlaying = NO;
    self.routeChangedWhilePlaying = NO;
    
    // video 将直接播放，replayer 也直接播放
    if (self.videoPlayer.currentItem.isPlaybackLikelyToKeepUp) {
        DLog(@"play directly");
        [self.replayer play];
    }
}

- (void)pause
{
    self.pauseReson = PauseReasonVideoPause;
    [self.videoPlayer pause];
    [self.replayer pause];
}

- (void)updateReplayerPhase:(WhitePlayerPhase)phase
{
    // replay 处于缓冲状态
    if (phase == WhitePlayerPhaseBuffering || phase == WhitePlayerPhaseWaitingFirstFrame) {
        self.replayerBufferring = YES;
        [self pauseForReplayerBuffing];
    // 进入播放状态，或者暂停状态，player 都已经缓存完
    } else if (phase == WhitePlayerPhasePlaying || phase == WhitePlayerPhasePause) {
        self.replayerBufferring = NO;
        [self replayerReadyToPlay];
    }
}

- (void)pauseForReplayerBuffing
{
    DLog(@"pauseForReplayerBuffing");
    self.pauseReson = PauseReasonRePlayerBuffering;
    [self.videoPlayer pause];
}

- (void)replayerReadyToPlay
{

    /*
     1. video 缓冲完毕，之前因为 replayer 在缓冲，暂停 video（rate 为 0）；需要恢复 video 播放
     2. video 实际在播放；不做任何事情
     3. 其他情况，暂停 replayer，等待 video 可以播放
     */
    if (self.pauseReson == PauseReasonRePlayerBuffering && [self hasEnoughBuffer]) {
        [self.videoPlayer play];
    } else if ([self videoDesireToPlay] && [self hasEnoughBuffer]) {
        DLog(@"continue play and do nothing");
    } else {
        // video 处于缓冲中，暂停播放 replayer
        DLog(@"wait for video");
        [self pauseReplayer];
    }
}

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler
{
    NSTimeInterval seekTime = CMTimeGetSeconds(time);
    [self.replayer seekToScheduleTime:seekTime];
    DLog(@"seekTime: %f", seekTime);
    __weak typeof(self)weakSelf = self;
    [self.videoPlayer seekToTime:time completionHandler:^(BOOL finished) {
        NSTimeInterval realTime = CMTimeGetSeconds(weakSelf.videoPlayer.currentItem.currentTime);
        DLog(@"realTime: %f", realTime);
        // AVPlayer 的 seek 不完全准确, seek 完以后，根据真实时间，重新 seek
        [weakSelf.replayer seekToScheduleTime:realTime];
        if (finished) {
            completionHandler(finished);
        }
    }];
}

@end
