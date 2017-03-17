//
//  WXVideoEncoder.h
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol WXVideoEncoderDelegate;

@interface WXVideoEncoder : NSObject


//delegate
/**
 *  视频编码代理
 */
@property (nonatomic, assign) id<WXVideoEncoderDelegate> delegate;

/**
 创建资源

 @param width 宽
 @param height 高
 @param frameInterval 关键帧间隔
 @return 状态码
 */
- (WXResult)createWithWidth:(int)width
                     height:(int)height
              frameInterval:(int)frameInterval;

/**
 编码数据

 @param pixelBuffer buffer
 @return 状态码
 */
- (WXResult)encode:(CVPixelBufferRef)pixelBuffer;

/**
 结束编码

 @return 状态码
 */
- (WXResult)endEncode;



@end

@protocol WXVideoEncoderDelegate <NSObject>

/**
 *  视频编码回调：注意不能卡住该回调，否则可能出现异常!!!
 *
 *  @param dataUnit 采集数据结构体：系统回调类型，
 *  @param videoEncoder 采集类对象
 */
- (void) wxVideoEncoderOutputNALUnit: (NALUnit)dataUnit
                         fromVideoEncoder: (const WXVideoEncoder *)videoEncoder;

@end
