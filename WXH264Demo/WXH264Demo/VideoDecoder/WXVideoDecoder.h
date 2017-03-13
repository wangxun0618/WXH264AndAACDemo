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

- (WXResult)decodeWithPath:(NSString *)path complete:(VideoDecodeCompleteBlock)complete;

- (WXResult)destroy;

@end
