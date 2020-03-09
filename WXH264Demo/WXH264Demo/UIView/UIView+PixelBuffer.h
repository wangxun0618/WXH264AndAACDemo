//
//  UIView+PixelBuffer.h
//  WXH264Demo
//
//  Created by xun wang on 2020/3/5.
//  Copyright © 2020 LYColud. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (PixelBuffer)
- (CVPixelBufferRef)CVPixelBufferRef;

- (UIImage *)imageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef;

+ (void)sampleBufferFromCVPixelBufferRef:(CVPixelBufferRef)pixelBuffer
                         sampleBufferRef:(CMSampleBufferRef)sampleBuffer;

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;
@end

NS_ASSUME_NONNULL_END
