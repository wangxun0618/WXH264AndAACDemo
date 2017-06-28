//
//  ViewController.m
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import "ViewController.h"
#import "WXVideoCapture.h"
#import "WXVideoEncoder.h"
#import "WXVideoDecoder.h"
#import "WXCAEAGLLayer.h"
#import "WXAudioCapture.h"
#import "WXAACEncoder.h"

@interface ViewController () <WXVideoCaptureDelegate,WXVideoEncoderDelegate,WXAudioCaptureDelegate>
{
    WXVideoCapture              *   wx_videoCapture;
    WXVideoEncoder              *   wx_videoEncoder;
    WXVideoDecoder              *   wx_videoDecoder;
    WXCAEAGLLayer               *   wx_caeaglLayer;
    WXAudioCapture              *   wx_audioCapture;
    WXAACEncoder                *   wx_aacEncoder;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 视频
    wx_videoCapture = [[WXVideoCapture alloc] init];
    wx_videoCapture.delegate = self;
    [wx_videoCapture create];
    NSLog(@">>>>>> %f",self.view.frame.size.width);
    
    [wx_videoCapture setPreview:self.view frame:CGRectMake(0, 0, self.view.frame.size.height/2*0.75, self.view.frame.size.height/2)];
    wx_videoEncoder = [[WXVideoEncoder alloc] init];
    wx_videoEncoder.delegate = self;
    [wx_videoEncoder createWithWidth:480 height:640 frameInterval:30];
    
    wx_videoDecoder = [[WXVideoDecoder alloc] init];
    
    wx_caeaglLayer = [[WXCAEAGLLayer alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height/2)];
    [self.view.layer insertSublayer:wx_caeaglLayer atIndex:0];
    
    // 音频
    wx_audioCapture = [[WXAudioCapture alloc] init];
    [wx_audioCapture create];
    wx_audioCapture.delegate = self;
    [wx_audioCapture openMicrophoneWithDevice];
    
    wx_aacEncoder = [[WXAACEncoder alloc] init];
}


- (IBAction)openCamera:(UIButton *)sender {
    [wx_videoCapture openCameraWithDevicePosition:AVCaptureDevicePositionBack resolution:WXCaptureCameraQuality640x480];
}

- (IBAction)switchCamera:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [wx_videoCapture switchCamera:AVCaptureDevicePositionFront];
    } else {
        [wx_videoCapture switchCamera:AVCaptureDevicePositionBack];
    }
}

- (IBAction)stopCamera:(UIButton *)sender {
    [wx_videoCapture closeCamera];
}
- (IBAction)decodeButton:(UIButton *)sender {
        
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.h264"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [wx_videoDecoder decodeWithPath:filePath complete:^(CVPixelBufferRef pixelBuffer) {
            NSLog(@">>> pixelBuffer = %@",pixelBuffer);
            wx_caeaglLayer.pixelBuffer = pixelBuffer;
        }];
    });
}
- (IBAction)destroyButton:(UIButton *)sender {
    [wx_videoCapture destroy];
//    [wx_videoDecoder destroy];
}

-(void)wxVideoCaptureOutputSampleBuffer:(const CMSampleBufferRef)sampleBuffer
                       fromVideoCapture:(const WXVideoCapture *)videoCapture {
    
    [wx_videoEncoder encode:CMSampleBufferGetImageBuffer(sampleBuffer)];
}

-(void)wxVideoEncoderOutputNALUnit:(NALUnit)dataUnit
                  fromVideoEncoder:(const WXVideoEncoder *)videoEncoder {
    
        NSLog(@">>>> dataUnit type %d ,  %02x",dataUnit.type,dataUnit.data[0]);
}

- (void) wxAudioCaptureOutputSampleBuffer: (const CMSampleBufferRef)sampleBuffer
                         fromAudioCapture: (const WXAudioCapture *)audioCapture {
    
    [wx_aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
//        NSLog(@">>>> auido encode data = %@",encodedData);
    }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
