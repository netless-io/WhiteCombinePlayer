//
//  WhiteCombinePlayer.h
//  WhiteSDK
//
//  Created by yleaf on 2019/7/11.
//

#import <Foundation/Foundation.h>
#import <White-SDK-iOS/WhiteSDK.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WhiteCombineDelegate <NSObject>

@optional


/**
 进入缓冲状态
 */
- (void)combinePlayerStartBuffering;


/**
 结束缓冲状态，开始播放
 */
- (void)combinePlayerEndBuffering;

/**
 视频播放结束
 */
- (void)videoPlayerDidFinish;

/**
 播放状态变化，由播放变停止，或者由暂停变播放

 @param isPlaying 是否正在播放
 */
- (void)combinePlayerPlayStateChange:(BOOL)isPlaying;


/**
 videoPlayer 无法进行播放，需要重新创建 CombinePlayer 进行播放

 @param error 错误原因
 */
- (void)combinePlayerError:(NSError *)error;

/**
 缓冲进度更新

 @param loadedTimeRanges 数组内元素为 CMTimeRange，使用 CMTimeRangeValue 获取 CMTimeRange，是 video 已经加载了的缓存
 */
- (void)loadedTimeRangeChange:(NSArray<NSValue *> *)loadedTimeRanges;
@end

/**
 同步普通 AVPlayer 与 WhitePlayer 的播放状态。
 某一个进入缓冲状态，另一个则暂停等待。
 */
@interface WhiteCombinePlayer : NSObject

@property (nonatomic, strong, readonly) AVPlayer *videoPlayer;
@property (nonatomic, strong, readonly) WhitePlayer *replayer;

@property (nonatomic, weak) id<WhiteCombineDelegate> delegate;

- (instancetype)initWithVideoPlayer:(AVPlayer *)player replayer:(WhitePlayer *)replayer;
- (instancetype)initWithVideoUrl:(NSURL *)videoUrl replayer:(WhitePlayer *)replayer;

- (NSTimeInterval)videoDuration;

- (void)play;
- (void)pause;
- (void)updateReplayerPhase:(WhitePlayerPhase)phase;

- (void)seekToTime:(CMTime)time completionHandler:(void (^)(BOOL finished))completionHandler;

@end

NS_ASSUME_NONNULL_END
