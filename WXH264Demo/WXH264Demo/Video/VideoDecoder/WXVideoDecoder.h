//
//  WXVideoDecoder.h
//  WXH264Demo
//
//  Created by ABC on 17/3/9.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

typedef void(^VideoDecodeCompleteBlock)(CVPixelBufferRef pixelBuffer);

@interface WXVideoDecoder : NSObject

/**
 视频解码

 @param path 视频路径
 @param complete 完成回调
 @return 状态码
 */
- (WXResult)decodeWithPath:(NSString *)path complete:(VideoDecodeCompleteBlock)complete;

/**
 销毁

 @return 状态码
 */
- (WXResult)destroy;

@end
