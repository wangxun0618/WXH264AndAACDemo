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

@interface ViewController () <WXVideoCaptureDelegate,WXVideoEncoderDelegate>
{
    WXVideoCapture              *wx_videoCapture;
    WXVideoEncoder              *wx_videoEncoder;
    WXVideoDecoder              *wx_videoDecoder;
    WXCAEAGLLayer               *wx_caeaglLayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    wx_videoCapture = [[WXVideoCapture alloc] init];
    wx_videoCapture.delegate = self;
    [wx_videoCapture create];
    
    [wx_videoCapture setPreview:self.view frame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2)];
    wx_videoEncoder = [[WXVideoEncoder alloc] init];
    wx_videoEncoder.delegate = self;
    [wx_videoEncoder createWithWidth:480 height:640 frameInterval:30];
    
    wx_videoDecoder = [[WXVideoDecoder alloc] init];
    
    wx_caeaglLayer = [[WXCAEAGLLayer alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height/2)];
    [self.view.layer insertSublayer:wx_caeaglLayer atIndex:0];
    
}

- (IBAction)openCamera:(UIButton *)sender {
    [wx_videoCapture openCameraWithDevicePosition:AVCaptureDevicePositionFront resolution:WXCaptureCameraQuality640x480];
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
    [wx_videoDecoder destroy];
}

-(void)wxVideoCaptureOutputSampleBuffer:(const CMSampleBufferRef)sampleBuffer fromVideoCapture:(const WXVideoCapture *)videoCapture {
    [wx_videoEncoder encode:CMSampleBufferGetImageBuffer(sampleBuffer)];
}

-(void)wxVideoEncoderOutputNALUnit:(NALUnit)dataUnit fromVideoEncoder:(const WXVideoEncoder *)videoEncoder {
    
    //    [wx_videoDecoder wx_decodeWithData:dataUnit];
    //    NSLog(@">>>> pixelBuffer = %@", pixelBuffer);
    //    NSLog(@">>>> dataUnit type %d ,  %02x",dataUnit.type,dataUnit.data[0]);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
