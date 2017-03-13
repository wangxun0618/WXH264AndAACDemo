//
//  WXVideoCapture.m
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import "WXVideoCapture.h"

@interface WXVideoCapture() <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession            * wx_captureSession;
    AVCaptureDeviceInput        * wx_deviceInput;
    AVCaptureVideoDataOutput    * wx_videoOutput;
    AVCaptureVideoPreviewLayer  * wx_previewLayer;
}

@end

@implementation WXVideoCapture

- (WXResult) create {
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    wx_captureSession = captureSession;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice  defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error;
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    wx_deviceInput = videoDeviceInput;
    if (error) {
        return WXResultFail;
    }
    
    if ([wx_captureSession canAddInput:videoDeviceInput]) {
        [wx_captureSession addInput:videoDeviceInput];
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    wx_videoOutput = videoOutput;
    dispatch_queue_t videoQueue = dispatch_queue_create("com.videoCapture.queue", DISPATCH_QUEUE_SERIAL);
    [wx_videoOutput setSampleBufferDelegate:self queue:videoQueue];
    if ([wx_captureSession canAddOutput:wx_videoOutput]) {
        [wx_captureSession addOutput:wx_videoOutput];
    } else {
        return WXResultFail;
    }
    
    return WXResultNoErr;
}

- (WXResult) setVideoFrameRate: (NSInteger)frameRate {
    return 1;
}

- (WXResult) openCameraWithDevicePosition: (AVCaptureDevicePosition)position
                               resolution: (WXCaptureCameraQuality)resolution {
    
    [self switchCamera:position];
    
    NSString *sessionPreset;
    switch (resolution) {
        case WXCaptureCameraQuality352x288:
            sessionPreset = AVCaptureSessionPreset352x288;
            break;
        case WXCaptureCameraQuality640x480:
            sessionPreset = AVCaptureSessionPreset640x480;
            break;
        case WXCaptureCameraQuality960x540:
            sessionPreset = AVCaptureSessionPresetiFrame960x540;
            break;
        case WXCaptureCameraQuality1280x720:
            sessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case WXCaptureCameraQuality1920x1080:
            sessionPreset = AVCaptureSessionPreset1920x1080;
            break;
        case WXCaptureCameraQuality3840x2160:
            sessionPreset = AVCaptureSessionPreset3840x2160;
            break;
    }
//    设置session显示分辨率
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [wx_captureSession setSessionPreset:sessionPreset];
    else
        [wx_captureSession setSessionPreset:AVCaptureSessionPresetPhoto];

    [wx_captureSession startRunning];
    
    return WXResultNoErr;
}

- (WXResult) setPreview: (UIView *)preview
                  frame: (CGRect)frame{
    AVCaptureVideoPreviewLayer *previedLayer = [AVCaptureVideoPreviewLayer layerWithSession:wx_captureSession];
    previedLayer.frame = frame;
    [preview.layer insertSublayer:previedLayer atIndex:0];
    return WXResultNoErr;
}

- (WXResult) closeCamera {
    
    [wx_captureSession stopRunning];
    return WXResultNoErr;
}

- (WXResult) turnTorchAndFlashOn: (BOOL)on {
    return WXResultNoErr;
}

- (WXResult)switchCamera:(AVCaptureDevicePosition)position {
    
    // 获取当前设备方向
    AVCaptureDevicePosition curPosition = wx_deviceInput.device.position;
    
    if (curPosition == position) {
        return WXResultNoErr;
    }
    // 创建设备输入对象
    AVCaptureDevice *captureDevice = [AVCaptureDevice  defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
    
    // 获取改变的摄像头输入设备
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];

    // 移除之前摄像头输入设备
    [wx_captureSession removeInput:wx_deviceInput];
    
    // 添加新的摄像头输入设备
    [wx_captureSession addInput:videoDeviceInput];
    
    // 记录当前摄像头输入设备
    wx_deviceInput = videoDeviceInput;
    return WXResultNoErr;
}

- (WXResult)destroy {
    
    return WXResultNoErr;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    NSLog(@">>>width:%zu height: %zu",CVPixelBufferGetWidth(buffer),CVPixelBufferGetHeight(buffer));
    [self.delegate wxVideoCaptureOutputSampleBuffer:sampleBuffer fromVideoCapture:self];
}

@end
