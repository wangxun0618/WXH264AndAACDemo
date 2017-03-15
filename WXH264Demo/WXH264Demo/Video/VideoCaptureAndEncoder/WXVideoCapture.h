//
//  WXVideoCapture.h
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol WXVideoCaptureDelegate;

@interface WXVideoCapture : NSObject

//delegate
/**
 *  视频采集代理
 */
@property (nonatomic, assign) id<WXVideoCaptureDelegate> delegate;

/**
 *  创建资源：创建内部使用的相关资源
 *  !!!需要先调用该方法才正常使用内部资源!!! 如果不调用该接口，可能导致某些功能不能正常使用
 *
 *  @return 状态码
 */
- (WXResult) create;
/**
 *  设置采集帧率
 *
 *  @param frameRate 帧率(1-30fps可设置) 如：30是30fps，如果不调用该接口则默认15fps!!!
 *
 *  @return 状态码
 */
- (WXResult) setVideoFrameRate: (NSInteger)frameRate;

/**
 *  设置预览窗口：如果不预览原始采集数据请勿设置预览窗口，
 *
 *  @param preview 预览窗口
 *  @param frame   窗口位置
 */
- (WXResult) setPreview: (UIView *)preview
                  frame: (CGRect)frame;

/**
 *  打开摄像头：开始采集
 *
 *  @param position     摄像头位置：前后置
 *  @param resolution   分辨率：分辨率请熟知各设备能支持的大小。否则会开启失败!!!
 */
- (WXResult) openCameraWithDevicePosition: (AVCaptureDevicePosition)position
                               resolution: (WXCaptureCameraQuality)resolution;

/**
 *  关闭摄像头：停止采集
 *
 *  @return 状态码
 */
- (WXResult) closeCamera;

/**
 *  开关闪光灯
 *
 *  @param on YES:打开、NO:关闭
 *
 *  @return 状态码
 */
- (WXResult) turnTorchAndFlashOn: (BOOL)on;

/**
 *  切换摄像头
 *
 *  @param position 摄像头位置
 *
 *  @return 状态码
 */

- (WXResult)switchCamera:(AVCaptureDevicePosition)position;


/**
 *  释放资源:退出时候一定要调用
 *
 *  @return 状态码
 */
- (WXResult)destroy;

@end

@protocol WXVideoCaptureDelegate <NSObject>

/**
 *  视频采集回调：注意不能卡住该回调，否则可能出现异常!!!
 *
 *  @param sampleBuffer 采集数据结构体：系统回调类型，
 *  @param videoCapture 采集类对象
 */
- (void) wxVideoCaptureOutputSampleBuffer: (const CMSampleBufferRef)sampleBuffer
                      fromVideoCapture: (const WXVideoCapture *)videoCapture;

@end
