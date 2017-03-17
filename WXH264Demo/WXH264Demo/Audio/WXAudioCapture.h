//
//  WXAudioCapture.h
//  WXH264Demo
//
//  Created by ABC on 17/3/15.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol WXAudioCaptureDelegate;

@interface WXAudioCapture : NSObject

//delegate
/**
 *  音频采集代理
 */
@property (nonatomic, assign) id<WXAudioCaptureDelegate> delegate;

- (WXResult) create;

//- (WXResult) setTheLengthOfEachFrameToReadData: (unsigned int)readLength;

- (WXResult) openMicrophoneWithDevice;

- (WXResult) closeMicrophone;

- (WXResult) destroy;

@end

@protocol WXAudioCaptureDelegate <NSObject>

/**
 *  音频采集回调：注意不能卡住该回调，否则可能出现异常!!!
 *
 *  @param sampleBuffer 采集数据结构体：系统回调类型，
 *  @param audioCapture 采集类对象
 */
- (void) wxAudioCaptureOutputSampleBuffer: (const CMSampleBufferRef)sampleBuffer
                         fromAudioCapture: (const WXAudioCapture *)audioCapture;

@end
