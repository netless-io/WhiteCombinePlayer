# WhiteCombinePlayer

[![CI Status](https://img.shields.io/travis/leavesster/WhiteCombinePlayer.svg?style=flat)](https://travis-ci.org/leavesster/WhiteCombinePlayer)
[![Version](https://img.shields.io/cocoapods/v/WhiteCombinePlayer.svg?style=flat)](https://cocoapods.org/pods/WhiteCombinePlayer)
[![License](https://img.shields.io/cocoapods/l/WhiteCombinePlayer.svg?style=flat)](https://cocoapods.org/pods/WhiteCombinePlayer)
[![Platform](https://img.shields.io/cocoapods/p/WhiteCombinePlayer.svg?style=flat)](https://cocoapods.org/pods/WhiteCombinePlayer)

**该库功能已经默认集成在[whiteboard开源SDK](https://github.com/netless-io/Whiteboard-iOS) 中，当前库不再维护。**

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

WhiteCombinePlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WhiteCombinePlayer'
```

## how to use

```Objective-C
WhiteCombinePlayer *combinePlayer = [[WhiteCombinePlayer alloc] initWithVideoUrl:[NSURL URLWithString:kM3u8] replayer:player];
combinePlayer.delegate = (id<WhiteCombineDelegate>)self;
```

```Objective-C
// WhiteCombineDelegate 回调
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
```

## implement

[实现逻辑](./implement.md)

## License

WhiteCombinePlayer is available under the MIT license. See the LICENSE file for more info.
