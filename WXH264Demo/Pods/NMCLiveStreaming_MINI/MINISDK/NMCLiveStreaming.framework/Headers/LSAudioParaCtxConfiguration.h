//
//  LSAudioParaCtxConfiguration.h
//  LSMediaCapture
//
//  Created by taojinliang on 2017/7/6.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSAudioParaCtxConfiguration : NSObject

/**
 音频的样本采集率:默认44100
 */
@property(nonatomic, assign) NSInteger samplerate;

/**
 音频采集的通道数:单声道，双声道，默认单声道
 */
@property(nonatomic, assign) NSInteger numOfChannels;

/**
 音频采集的帧大小:默认2048
 */
@property(nonatomic, assign) NSInteger frameSize;

/**
 音频编码码率:默认64k:64000
 */
@property(nonatomic, assign) NSInteger bitrate;

/**
 是否使用外部音频采集，默认不开启
 */
@property(nonatomic, assign) BOOL isUseExternalCapture;

/**
 是否进行音频前处理，默认开启
 */
@property(nonatomic, assign) BOOL isUseAudioPreProcess;

/**
 创建一个音频默认参数配置
 
 @return 音频默认参数配置
 */
+ (instancetype)defaultAudioConfiguration;

@end


