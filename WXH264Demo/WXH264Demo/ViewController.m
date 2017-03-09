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

@interface ViewController () <WXVideoCaptureDelegate>
{
    WXVideoCapture              *wx_videoCapture;
    WXVideoEncoder              *wx_videoEncoder;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    wx_videoCapture = [[WXVideoCapture alloc] init];
    wx_videoCapture.delegate = self;
    [wx_videoCapture create];
    
    [wx_videoCapture setPreview:self.view frame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    wx_videoEncoder = [[WXVideoEncoder alloc] init];
    [wx_videoEncoder createWithWidth:540 height:960 frameInterval:30];
}

- (IBAction)openCamera:(UIButton *)sender {
    [wx_videoCapture openCameraWithDevicePosition:AVCaptureDevicePositionFront resolution:WXCaptureCameraQuality960x540];
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

-(void)wxVideoCaptureOutputSampleBuffer:(const CMSampleBufferRef)sampleBuffer fromVideoCapture:(const WXVideoCapture *)videoCapture {
    [wx_videoEncoder encode:CMSampleBufferGetImageBuffer(sampleBuffer)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
