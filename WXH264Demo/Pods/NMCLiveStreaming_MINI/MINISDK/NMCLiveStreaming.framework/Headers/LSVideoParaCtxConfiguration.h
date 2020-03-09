//
//  LSVideoParaCtxConfiguration.h
//  LSMediaCapture
//
//  Created by taojinliang on 2017/7/6.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, LSVideoParamQuality) {
    //!< 视频分辨率：低清 352*288 帧率：20 码率：300Kbps
    LSVideoParamQuality_Low,
    //!< 视频分辨率：标清 480*270 帧率：20 码率：400Kbps 
    LSVideoParamQuality_Medium1,
    //!< 视频分辨率：标清 480*360 帧率：20 码率：450Kbps
    LSVideoParamQuality_Medium2,
    //!< 视频分辨率：高清 640*360 帧率：20 码率：500Kbps
    LSVideoParamQuality_High1,
    //!< 视频分辨率：高清 640*480 帧率：20 码率：600Kbps
    LSVideoParamQuality_High2,
    //!< 视频分辨率：超清 960*540 帧率：20 码率：800Kbps
    LSVideoParamQuality_Super,
    //!< 视频分辨率：超高清 (1280*720) 帧率：15 码率：1200Kbps
    LSVideoParamQuality_Super_High,
    //!< 视频分辨率：超超高清 (1920*1080) 帧率：15 码率：2000Kbps
    LSVideoParamQuality_Super_Super_High
};

@interface LSVideoParaCtxConfiguration : NSObject

/**
 视频的帧率.(0~30],默认为20
 */
@property(nonatomic, assign) NSInteger  fps;

/**
 码率，默认为500000
 */
@property(nonatomic, assign) NSInteger bitrate;

/**
 视频分辨率，默认高清
 */
@property(nonatomic, assign) LSVideoStreamingQuality videoStreamingQuality;

/**
 视频采集前后摄像头，默认前置
 */
@property(nonatomic, assign) LSCameraPosition cameraPosition;

/**
 视频采集方向，默认竖屏
 */
@property(nonatomic, assign) LSCameraOrientation interfaceOrientation;

/**
 视频显示端比例，默认16:9
 */
@property(nonatomic, assign) LSVideoRenderScaleMode videoRenderMode;

/**
 是否开启摄像头flash功能，默认开启
 */
@property(nonatomic, assign) BOOL isCameraFlashEnabled;

/**
 是否需要打开摄像头收视响应变焦功能，默认开启.
 */
@property(nonatomic, assign) BOOL isCameraZoomPinchGestureOn;

/**
 是否镜像前置摄像头预览.(针对本地预览)，默认开启
 */
@property(nonatomic, assign) BOOL isFrontCameraMirroredPreView;

/**
 是否镜像前置摄像头编码.(针对拉流端)，默认不开启
 */
@property(nonatomic, assign) BOOL isFrontCameraMirroredCode;

/**
 是否打开滤镜支持功能.默认开启
 */
@property(nonatomic, assign) BOOL isVideoFilterOn;

/**
 滤镜类型，默认自然
 */
@property(nonatomic, assign) LSGpuImageFilterType filterType;

/**
 是否打开水印支持.默认开启
 */
@property(nonatomic, assign) BOOL isVideoWaterMarkEnabled;

/**
 是否打开qos功能.默认开启
 */
@property(nonatomic, assign) BOOL isQosOn;

/**
 Qos场景区分,只在Qos开启之后才有用
 */
@property(nonatomic, assign) LSVideoEncodeSceneType sceneType;

/**
 是否输出RGB数据.默认不开启
 */
@property(nonatomic, assign) BOOL isOutputRGB;

/**
 是否使用外部视频采集，默认不开启
 */
@property(nonatomic, assign) BOOL isUseExternalCapture;

/**
 是否使用硬件编码B帧，只在开启硬件编码的情况下才使用,默认开启
 */
@property(nonatomic, assign) BOOL isUseHwBFrame;


/**
 创建一个视频默认参数配置
 
 @return 视频默认参数配置
 */
+ (instancetype)defaultVideoConfiguration:(LSVideoParamQuality)videoParamQuality;

@end
