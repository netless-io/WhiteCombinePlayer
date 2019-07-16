//
//  WhiteVideoView.m
//  WhiteCombinePlayer
//
//  Created by yleaf on 2019/7/15.
//

#import "WhiteVideoView.h"
#import <AVFoundation/AVFoundation.h>

@implementation WhiteVideoView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setAVPlayer:(AVPlayer *)player;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [(AVPlayerLayer *)self.layer setPlayer:player];
    });
}

@end
