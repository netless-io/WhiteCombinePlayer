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
#import <WhiteSDK.h>
#import <Masonry.h>

@interface WhiteViewController ()
@property (nonatomic, strong) WhiteBoardView *boardView;
@property (nonatomic, strong) WhiteSDK *sdk;

@property (nonatomic, strong) WhiteVideoView *videoView;
@property (nonatomic, strong) WhiteCombinePlayer *combinePlayer;

@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation WhiteViewController

static NSString *const kM3u8 = @"https://d2zihajmogu5jn.cloudfront.net/sintel/master.m3u8";
static NSString *const kUUID = @"b8343837f65d4f5c83925aa236ce543d";
static NSString *const kRoomToken = @"WHITEcGFydG5lcl9pZD1OZ3pwQWNBdlhiemJERW9NY0E0Z0V3RTUwbVZxM0NIbDJYV0Ymc2lnPWUxNGQ0MzgyMjkzZGMyOGMwNWE4NjE2ZTBmN2QxNDY4MzkyZGRhNDE6YWRtaW5JZD0yMTYmcm9vbUlkPWI4MzQzODM3ZjY1ZDRmNWM4MzkyNWFhMjM2Y2U1NDNkJnRlYW1JZD0zNDEmcm9sZT1yb29tJmV4cGlyZV90aW1lPTE1OTQ3Mzk2NTkmYWs9Tmd6cEFjQXZYYnpiREVvTWNBNGdFd0U1MG1WcTNDSGwyWFdGJmNyZWF0ZV90aW1lPTE1NjMxODI3MDcmbm9uY2U9MTU2MzE4MjcwNjgzMzAw";
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self initSDK];
    
    WhitePlayerConfig *config = [[WhitePlayerConfig alloc] initWithRoom:kUUID roomToken:kRoomToken];
    [self.sdk createReplayerWithConfig:config callbacks:(id<WhitePlayerEventDelegate>)self completionHandler:^(BOOL success, WhitePlayer * _Nullable player, NSError * _Nullable error) {
        if (player) {
            self.combinePlayer = [[WhiteCombinePlayer alloc] initWithVideoUrl:[NSURL URLWithString:kM3u8] replayer:player];
            [self.videoView setAVPlayer:self.combinePlayer.videoPlayer];
        }
    }];
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
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *pause = [[UIBarButtonItem alloc] initWithTitle:@"pause" style:UIBarButtonItemStyleDone target:self action:@selector(pause:)];
    [self.toolbar setItems:@[play, space, pause]];
        
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
