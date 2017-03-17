//
//  WXAudioCapture.m
//  WXH264Demo
//
//  Created by ABC on 17/3/15.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import "WXAudioCapture.h"

@interface WXAudioCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate>

@end

@implementation WXAudioCapture
{
    AVCaptureSession *wx_audioSession;
}

- (WXResult) create {
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    wx_audioSession = captureSession;
    
    //2、获取麦克风
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    //3、创建对应音频设备输入对象
    AVCaptureInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    //4、添加音频
    if ([captureSession canAddInput:audioDeviceInput]) {
        [captureSession addInput:audioDeviceInput];
    }
    
    //5、获取音频输入输出设备
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    //6、设置代理 捕获音频数据
    //注意:队列必须是串行队列，才能获取到数据，而且不能为空
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
    if ([captureSession canAddOutput:audioOutput]) {
        [captureSession addOutput:audioOutput];
    }
    
    return WXResultNoErr;
}

- (WXResult) openMicrophoneWithDevice {
    //7、启动会话
    [wx_audioSession startRunning];
    return WXResultNoErr;
}

- (WXResult) closeMicrophone {
    [wx_audioSession stopRunning];
    
    return WXResultNoErr;
}

- (WXResult) destroy {
    
    if (wx_audioSession) {
        [wx_audioSession stopRunning];
        wx_audioSession = nil;
    }
    
    return WXResultNoErr;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.delegate wxAudioCaptureOutputSampleBuffer:sampleBuffer fromAudioCapture:self];
    NSLog(@">>>>>------%@",sampleBuffer);
}


@end
