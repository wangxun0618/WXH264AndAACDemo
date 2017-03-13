//
//  WXCAEAGLLayer,h
//  WXH264Demo
//
//  Created by ABC on 17/3/9.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>


@interface WXCAEAGLLayer : CAEAGLLayer

@property CVPixelBufferRef pixelBuffer;

- (id)initWithFrame:(CGRect)frame;

- (void)resetRenderBuffer;

@end
