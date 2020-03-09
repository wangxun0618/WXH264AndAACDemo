//
//  LSLiveStreamingParaCtxConfiguration.h
//  LSMediaCapture
//
//  Created by taojinliang on 2017/7/7.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LSAudioParaCtxConfiguration,LSVideoParaCtxConfiguration;

@interface LSLiveStreamingParaCtxConfiguration : NSObject

/**
 是否开启硬件编码类型，默认开启
 */
@property(nonatomic, assign) LSHardWareEncEnable eHaraWareEncType;

/**
 推流类型：音视频，视频，音频，默认为音视频
 */
@property(nonatomic, assign) LSOutputStreamType eOutStreamType;

/**
 推流协议：RTMP,FLV.默认为RTMP
 */
@property(nonatomic, assign) LSOutputFormatType eOutFormatType;

/**
 推流视频相关参数.
 */
@property(nonatomic, strong) LSVideoParaCtxConfiguration* sLSVideoParaCtx;

/**
 推流音频相关参数.
 */
@property(nonatomic, strong) LSAudioParaCtxConfiguration* sLSAudioParaCtx;

/**
 是否上传sdk日志，默认开启
 */
@property(nonatomic, assign) BOOL uploadLog;

/**
 同步时间戳透传开关，默认关闭，推流类型必须包含视频，同时需要网易云播放器支持
 */
@property(nonatomic, assign) BOOL syncTimestamp;

/**
 同步时间戳基准:true为从0开始的基准，false为相对机器开机时间基准，默认为true
 */
@property(nonatomic, assign) BOOL syncTimestampBaseline;

/**
 网易云透传时间戳，但完全透传功能需要联系网易云开通
 */
@property(nonatomic, assign) BOOL streamTimestampPassthrough;

/**
 私有化配置开关，默认关闭
 */
@property(nonatomic, assign) BOOL privateConfig;

/**
 创建一个直播默认参数配置
 
 @return 直播默认参数配置
 */
+ (instancetype)defaultLiveStreamingConfiguration;
@end
