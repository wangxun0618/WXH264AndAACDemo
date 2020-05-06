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
    UIImage                     *   image;
    BOOL isConnect;
    int  index;
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
    index = 0;
    _timer = [NSTimer timerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        _preView.backgroundColor = [UIColor randomColor];
        if (index == 0) {
            image = [UIImage imageNamed:@"test"];
            index++;
        } else {
            image = [UIImage imageNamed:@"bg_login"];
            index = 0;
        }

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
        
    
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(backgroundStopLiveStream:)
    name:UIApplicationDidEnterBackgroundNotification
      object:nil];
}

- (void)start {
    
    LSVideoParaCtxConfiguration *videoParaCtx = [LSVideoParaCtxConfiguration defaultVideoConfiguration:LSVideoParamQuality_High1];
    videoParaCtx.isUseExternalCapture = YES;
    videoParaCtx.videoRenderMode = LS_VIDEO_RENDER_MODE_SCALE_NONE;
    lsMediaStream = [[LSMediaCapture alloc] initLiveStream:@"rtmp://192.168.199.152:1935/zbcs/room" withVideoParaCtxConfiguration:videoParaCtx];
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
//        CVPixelBufferRef pixelBuffer = [_preView CVPixelBufferRef];
        
        CVPixelBufferRef pixelBuffer = [_preView pixelBufferFromCGImage:image.CGImage];
        
        CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
        CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timimgInfo, &sampleBuffer);
        [lsMediaStream externalInputSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
        CVBufferRelease(pixelBuffer);
    });
}

- (void)backgroundStopLiveStream:(NSNotificationCenter *)notification {
    UIApplication *app = [UIApplication sharedApplication];
    
    // 定义一个UIBackgroundTaskIdentifier类型(本质就是NSUInteger)的变量
    // 该变量将作为后台任务的标识符
    __block UIBackgroundTaskIdentifier backTaskId;
    backTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"===在额外申请的时间内依然没有完成任务===");
        // 结束后台任务
        [app endBackgroundTask:backTaskId];
    }];
    if(backTaskId == UIBackgroundTaskInvalid){
        NSLog(@"===iOS版本不支持后台运行,后台任务启动失败===");
        return;
    }
    
    // 将代码块以异步方式提交给系统的全局并发队列
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"===额外申请的后台任务时间为: %f===",app.backgroundTimeRemaining);
//        if(isConnect){
//            // 其他内存清理的代码也可以在此处完成
//            [lsMediaStream stopLiveStream:^(NSError *error) {
//                if (error == nil) {
//                    NSLog(@"退到后台的直播结束了");
//                    isConnect = NO;
//                    [app endBackgroundTask:backTaskId];
//                }else{
//                    NSLog(@"退到后台的结束直播发生错误");
//                    [app endBackgroundTask:backTaskId];
//                }
//            }];
//        }
    });
    
    
}


@end
