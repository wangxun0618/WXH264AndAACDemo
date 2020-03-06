//
//  PushMetalViewController.m
//  WXH264Demo
//
//  Created by xun wang on 2020/3/5.
//  Copyright © 2020 LYColud. All rights reserved.
//

#import "PushMetalViewController.h"
#import "WXAudioCapture.h"
#import "WXVideoCapture.h"
#import <LFLiveKit/LFLiveKit.h>
#import "UIView+PixelBuffer.h"
#import "UIColor+Extension.h"

//推流采集的视频流
@interface PushMetalViewController () <WXVideoCaptureDelegate,WXAudioCaptureDelegate,LFLiveSessionDelegate>
{
    WXVideoCapture              *   wx_videoCapture;
    
    LFLiveSession               *   wx_liveSession;

}

@property (nonatomic, strong) UIView *preView;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PushMetalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    [self.view addSubview:_preView];
    _timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        _preView.backgroundColor = [UIColor randomColor];
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];

    
    // 视频
    wx_videoCapture = [[WXVideoCapture alloc] init];
    wx_videoCapture.delegate = self;
    [wx_videoCapture create];
    NSLog(@">>>>>> %f",self.view.frame.size.width);
    
    [wx_videoCapture setPreview:self.view frame:CGRectMake(0, 0, self.view.frame.size.height/2*0.75, self.view.frame.size.height/2)];
    
    [wx_videoCapture openCameraWithDevicePosition:AVCaptureDevicePositionBack resolution:WXCaptureCameraQuality640x480];
    
        
    LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration defaultConfiguration];
    videoConfiguration.videoSize = CGSizeMake(self.view.bounds.size.width, 200);
    wx_liveSession = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:videoConfiguration captureType:LFLiveCaptureMaskAudioInputVideo];
    [wx_liveSession setRunning:YES];

    LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
    stream.url = @"rtmp://10.220.220.155:1935/zbcs/room";
    [wx_liveSession startLive:stream];
    wx_liveSession.delegate = self;
    

}

- (NSData *)dataFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
    Byte buffer[length];
    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
    NSData *data = [NSData dataWithBytes:buffer length:length];
    return data;
}


-(void)wxVideoCaptureOutputSampleBuffer:(const CMSampleBufferRef)sampleBuffer
                       fromVideoCapture:(const WXVideoCapture *)videoCapture {
        
    dispatch_async(dispatch_get_main_queue(), ^{
//        [wx_liveSession pushVideo:[_preView CVPixelBufferRef]];
        UIImage *image = [UIImage imageNamed:@"bg"];
        [wx_liveSession pushVideo:[_preView pixelBufferFromCGImage:image.CGImage]];
    });
    
}


- (void) wxAudioCaptureOutputSampleBuffer: (const CMSampleBufferRef)sampleBuffer
                         fromAudioCapture: (const WXAudioCapture *)audioCapture {
    
    [wx_liveSession pushAudio:[self dataFromSampleBuffer:sampleBuffer]];
}


#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    NSLog(@"liveStateDidChange: %ld", state);
    switch (state) {
    case LFLiveReady:
            NSLog(@"未连接");
        break;
    case LFLivePending:
            NSLog(@"连接中");

        break;
    case LFLiveStart:
            NSLog(@"已连接");

        break;
    case LFLiveError:
            NSLog(@"连接错误");

        break;
    case LFLiveStop:
            NSLog(@"未连接");
        break;
    default:
        break;
    }
}

/** live debug info callback */
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    NSLog(@"debugInfo uploadSpeed: ");
}

/** callback socket errorcode */
- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"errorCode: %ld", errorCode);
}

@end
