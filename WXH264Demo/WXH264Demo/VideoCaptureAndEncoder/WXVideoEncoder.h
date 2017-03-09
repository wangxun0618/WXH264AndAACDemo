//
//  WXVideoEncoder.h
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface WXVideoEncoder : NSObject

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
