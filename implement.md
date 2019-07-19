将 `avplayer` 与 white-sdk-ios 的回放组件(`replayer`)，进行播放状态的同步。当一方进入缓冲状态时，另一方暂停，等待前者缓冲完毕。

`CombinePlayer`以`AVPlayer`状态为主，辅助控制`replayer`。

以下为`combinePlayer`实现逻辑。
>以该格式显示的内容，需要开发者手动再对应位置进行实现。其余部分，`combinePlayer`均已经实现完成。

## 暂停处理

直接暂停两端

## 播放

主动开始播放`AVPlayer`，看情况操作`replayer`。

1. 检测`AVPlayer`状态，如果可以直接进行播放，则同时播放`replayer`。
1. 否则，根据`AVPlayer`缓冲状态变化，再进行播放（建议提前调用`replayer`的`seek`API，触发`replayer`缓存）。

## 进入缓冲

当一方进入缓冲时，另一方应该直接暂停。

>`AVPlayer` 与 `replayer` 均有提前加载缓冲的策略。  
在`replayer`创建成功后，可以直接调用`replayer`的`seekToScheduleTime:`，主动触发`replayer`缓冲。

### AVPlayer 缓冲

如果是本地下载，可以忽略本小节。
<details><summary>缓冲状态有两种情况：1. 调用播放 API，进入缓冲状态（此时 rate≠0），2. AVPlayer 创建后，自动加载缓冲。</summary>

对于网络视频，当 `avplayer` 设置 `rate = 1.0` 或调用 `play` API 时，`avplayer` 会查看缓冲数据。如果没有缓冲，则会先进入缓冲状态，等待数据加载。此时 `avplayer.currentItem.playbackBufferEmpty` 属性为 `true`。一般会使用 KVO 监听该属性，来获取缓冲开始通知。

当缓冲数据足够时，`AVPlayerItem` 会触发 `playbackLikelyToKeepUp` 为 true，使用 KVO 监听该属性，可以获取缓冲结束通知。

`avplayer` 进入缓冲状态时，`avplayer.rate` 仍然为 `1`，如果要获取，

参考资料：[IOS AVFOUNDATION PLAYBACK BENCHMARKS](https://medium.com/shakuro/ios-avfoundation-playback-benchmarks-255674a54848)

</details>

#### 处理

无论哪种情况，都直接暂停`replayer` 即可。

### replayer 缓冲

>`combinePlayer` 需要在 `replayer` 状态变化 `- (void)phaseChanged:(WhitePlayerPhase)phase` 回调中，手动调用 `[combinePlayer updateReplayerPhase:phase];`

具体可以查看 `combinePlayer`的`pauseForReplayerBuffing`实现。

#### 处理：

如果`avplayer`处于播放状态，则暂停`VideoPlayer`，并标记暂停原因为 `PauseReasonRePlayerBuffering`。

## 结束缓冲

### AVPlayer 结束缓冲

AVPlayer 有自动缓冲逻辑，所以需要确定，AVPlayer 是否处于想要播放的状态（rate≠0，或者暂停原因为等待 replayer 缓冲）

#### 1. 之前为了配合 replayer 缓冲，暂停了 AVPlayer

重新执行`combinePlayer` 播放逻辑，此时 AVPlayer 由于已经缓冲完毕，AVPlayer 会直接播放，并且 replayer 也会直接播放

#### 2. AVPlayer rate≠0

播放 replayer

#### 3. 其他情况

不做任何处理