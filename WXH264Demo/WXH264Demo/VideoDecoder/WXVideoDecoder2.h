//
//  WXVideoDecoder.h
//  WXH264Demo
//
//  Created by ABC on 17/3/9.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface WXVideoDecoder : NSObject

- (CVPixelBufferRef)wx_decodeWithData:(NALUnit)buffer;
- (WXResult)destroy;


@end
