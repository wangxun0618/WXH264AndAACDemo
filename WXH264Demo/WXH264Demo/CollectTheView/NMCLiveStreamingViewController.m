//
//  NMCLiveStreamingViewController.m
//  WXH264Demo
//
//  Created by xun wang on 2020/3/9.
//  Copyright © 2020 LYColud. All rights reserved.
//

#import "NMCLiveStreamingViewController.h"
#import "WXVideoCapture.h"
#import <NMCLiveStreaming/NMCLiveStreaming.h>

@interface NMCLiveStreamingViewController ()<WXVideoCaptureDelegate>
{
    WXVideoCapture              *   wx_videoCapture;
    LSMediaCapture              *   lsMediaStream;
    
    BOOL isConnect;
}

@property (nonatomic, strong) UIView *preView;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation NMCLiveStreamingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //     Do any additional setup after loading the view.
    _preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    _preView.backgroundColor = UIColor.yellowColor;
    [self.view addSubview:_preView];
    _timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        _preView.backgroundColor = [UIColor randomColor];
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];

    
    // 视频
    wx_videoCapture = [[WXVideoCapture alloc] init];
    wx_videoCapture.delegate = self;
    [wx_videoCapture setVideoFrameRate:20];
    [wx_videoCapture create];
    NSLog(@">>>>>> %f",self.view.frame.size.width);
        
    
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    [self.view addSubview:button];
    button.backgroundColor = UIColor.redColor;
    [button addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
        
}

- (void)start {
    
    LSVideoParaCtxConfiguration *videoParaCtx = [LSVideoParaCtxConfiguration defaultVideoConfiguration:LSVideoParamQuality_High1];
    videoParaCtx.isUseExternalCapture = YES;
    videoParaCtx.videoRenderMode = LS_VIDEO_RENDER_MODE_SCALE_NONE;
    lsMediaStream = [[LSMediaCapture alloc] initLiveStream:@"rtmp://10.220.220.210:1935/zbcs/room" withVideoParaCtxConfiguration:videoParaCtx];
    [lsMediaStream startVideoPreview:self.preView];
    [lsMediaStream startLiveStream:^(NSError *error) {
        NSLog(@"%@",error);
//        isConnect = YES;
        [wx_videoCapture openCameraWithDevicePosition:AVCaptureDevicePositionBack resolution:WXCaptureCameraQuality640x480];

    }];
}

- (void)wxVideoCaptureOutputSampleBuffer:(const CMSampleBufferRef)sampleBuffer
                        fromVideoCapture:(const WXVideoCapture *)videoCapture {
        
    [self sendSampleBuffer:sampleBuffer];
}

- (void)sendSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMSampleTimingInfo timimgInfo;
    CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timimgInfo);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CMVideoFormatDescriptionRef videoInfo = NULL;
        
        CMSampleBufferRef sampleBuffer = NULL;
        CVPixelBufferRef pixelBuffer = [_preView CVPixelBufferRef];
        
//        UIImage *image = [UIImage imageNamed:@"bg"];
//        CVPixelBufferRef pixelBuffer = [_preView pixelBufferFromCGImage:image.CGImage];
        
        CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
        CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timimgInfo, &sampleBuffer);
        [lsMediaStream externalInputSampleBuffer:sampleBuffer];
        
        CFRelease(pixelBuffer);
        CFRelease(sampleBuffer);
    });
}



@end
