//
//  WhiteViewController.m
//  WhiteCombinePlayer
//
//  Created by leavesster on 07/12/2019.
//  Copyright (c) 2019 leavesster. All rights reserved.
//

#import "WhiteViewController.h"
#import <WhiteCombinePlayer.h>
#import <WhiteCombinePlayer/WhiteVideoView.h>
#import <WhiteCombinePlayer/WhiteSliderView.h>
#import <WhiteSDK.h>
#import <Masonry.h>

@interface WhiteViewController ()

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, strong) WhiteBoardView *boardView;
@property (nonatomic, strong) WhiteSDK *sdk;

@property (nonatomic, strong) WhiteVideoView *videoView;
@property (nonatomic, strong) WhiteCombinePlayer *combinePlayer;

@property (nonatomic, strong) WhiteSliderView *progressView;
@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation WhiteViewController
static NSString *const kM3u8 = @"https://d2zihajmogu5jn.cloudfront.net/sintel/master.m3u8";
static NSString *const kUUID = @"93e64389b1fb4ba58a0c1d50d9ad47b1";
static NSString *const kRoomToken = @"WHITEcGFydG5lcl9pZD1OZ3pwQWNBdlhiemJERW9NY0E0Z0V3RTUwbVZxM0NIbDJYV0Ymc2lnPThmYWJkYTVmMjQyNjIyZGViYmI3ZjNhMDk5YmU1ZTgzYWYzYTc3OWU6YWRtaW5JZD0yMTYmcm9vbUlkPTkzZTY0Mzg5YjFmYjRiYTU4YTBjMWQ1MGQ5YWQ0N2IxJnRlYW1JZD0zNDEmcm9sZT1yb29tJmV4cGlyZV90aW1lPTE1OTUwOTM2MzUmYWs9Tmd6cEFjQXZYYnpiREVvTWNBNGdFd0U1MG1WcTNDSGwyWFdGJmNyZWF0ZV90aW1lPTE1NjM1MzY2ODMmbm9uY2U9MTU2MzUzNjY4MzQ4NzAw";

- (void)dealloc
{
    if (self.timeObserver) {
        [self.combinePlayer.videoPlayer removeTimeObserver:self.timeObserver];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self initSDK];
    
    WhitePlayerConfig *config = [[WhitePlayerConfig alloc] initWithRoom:kUUID roomToken:kRoomToken];
    [self.sdk createReplayerWithConfig:config callbacks:(id<WhitePlayerEventDelegate>)self completionHandler:^(BOOL success, WhitePlayer * _Nullable player, NSError * _Nullable error) {
        if (player) {
            self.combinePlayer = [[WhiteCombinePlayer alloc] initWithVideoUrl:[NSURL URLWithString:kM3u8] replayer:player];
            // 设置视频显示 view
            [self.videoView setAVPlayer:self.combinePlayer.videoPlayer];
            self.combinePlayer.delegate = (id<WhiteCombineDelegate>)self;
            [self setupVideoProgress];
            // 提前 seek，replayer 会提前读取缓存，可以减少 play 时，bufferring 等待时间
            [player seekToScheduleTime:0];
        } else {
            NSLog(@"error:%@", [error description]);
        }
    }];
}

- (void)setupVideoProgress
{
    __weak typeof(self)weakSelf = self;
    self.timeObserver = [self.combinePlayer.videoPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 4) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if ([weakSelf.combinePlayer videoDuration]) {
            weakSelf.progressView.value = CMTimeGetSeconds(time) / [weakSelf.combinePlayer videoDuration];
        }
    }];
}

#pragma mark - WhiteCombineDelegate
- (void)combinePlayerPlayStateChange:(BOOL)isPlaying
{
    NSLog(@"play:%d", isPlaying);
}

- (void)loadedTimeRangeChange:(NSArray<NSValue *> *)loadedTimeRanges
{
//    NSLog(@"%s: %@", __FUNCTION__, [loadedTimeRanges description]);
    CMTimeRange range = [[loadedTimeRanges firstObject] CMTimeRangeValue];
    NSTimeInterval sec = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
    NSTimeInterval duration = [self.combinePlayer videoDuration];
    if (duration && !isnan(sec)) {
        self.progressView.bufferValue = sec / duration;
    }
}

#pragma mark -
- (void)phaseChanged:(WhitePlayerPhase)phase;
{
    NSLog(@"%s:%ld", __FUNCTION__, (long)phase);
    [self.combinePlayer updateReplayerPhase:phase];
}

- (void)loadFirstFrame;
{
    
}

- (void)sliceChanged:(NSString *)slice;
{
    
}

- (void)playerStateChanged:(WhitePlayerState *)modifyState;
{
    
}

- (void)stoppedWithError:(NSError *)error;
{
    
}

- (void)scheduleTimeChanged:(NSTimeInterval)time;
{
    
}

- (void)errorWhenAppendFrame:(NSError *)error;
{
}

- (void)errorWhenRender:(NSError *)error;
{
    
}

- (void)fireMagixEvent:(WhiteEvent *)event
{
    
}

#pragma mark - Play control
- (void)play:(UIBarButtonItem *)item
{
    [self.combinePlayer play];
    
}

- (void)pause:(UIBarButtonItem *)item
{
    [self.combinePlayer pause];
}

#pragma mark - WhiteSDK
- (void)setupViews {
    
    self.videoView = [[WhiteVideoView alloc] init];
    // 展示用的 m3u8 有 3 秒黑屏，显示黑色时，就是加载成功
    self.videoView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.videoView];
    
    self.boardView = [[WhiteBoardView alloc] init];
    [self.view addSubview:self.boardView];
    
    self.toolbar = [[UIToolbar alloc] init];
    [self.view addSubview:self.toolbar];
    
    UIBarButtonItem *play = [[UIBarButtonItem alloc] initWithTitle:@"play" style:UIBarButtonItemStyleDone target:self action:@selector(play:)];
    self.progressView = [[WhiteSliderView alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
    UIBarButtonItem *progress = [[UIBarButtonItem alloc] initWithCustomView:self.progressView];
    UIBarButtonItem *pause = [[UIBarButtonItem alloc] initWithTitle:@"pause" style:UIBarButtonItemStyleDone target:self action:@selector(pause:)];
    [self.toolbar setItems:@[play, progress, pause]];
        
    if (@available(iOS 11, *)) {
    } else {
        //可以参考此处处理
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.videoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.left.right.equalTo(self.view);
        // 保持视频原始比例
        make.height.equalTo(self.videoView.mas_width).multipliedBy(544.0 / 1280.0);
    }];
    
    [self.boardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.videoView.mas_bottom);
        make.left.right.equalTo(self.view);
    }];
    
    [self.toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.boardView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.height.equalTo(@40);
        if (@available(iOS 11, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.view.mas_bottomMargin);
        }
    }];
}

- (void)initSDK {
    
    WhiteSdkConfiguration *config = [WhiteSdkConfiguration defaultConfig];
    
    config.debug = YES;
    config.userCursor = YES;
    
    self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:config commonCallbackDelegate:nil];
    
}

@end
