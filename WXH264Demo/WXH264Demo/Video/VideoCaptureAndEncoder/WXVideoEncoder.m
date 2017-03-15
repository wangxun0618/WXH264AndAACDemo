//
//  WXVideoEncoder.m
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#import "WXVideoEncoder.h"

@implementation WXVideoEncoder
{
    int currentFrame;
    VTCompressionSessionRef WEncodingSession;
    NSFileHandle *wFileHandle;
}

- (WXResult)createWithWidth:(int)width
                     height:(int)height
              frameInterval:(int)frameInterval {
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //1、设置当前帧为0
        currentFrame = 0;

        /**
         2、创建压缩编码会话,用于画面编码
         
         @param NULL 会话的分配器。 传递NULL以使用默认分配器。
         @param width 宽
         @param height 长
         @param kCMVideoCodecType_H264 编码类型
         @param NULL 指定必须使用的特定视频编码器。传递NULL，让视频工具箱选择一个编码器。
         @param NULL <#NULL description#>
         @param NULL <#NULL description#>
         @param didCompression 回调函数(回调是视频图像编码成功后调用)
         @param void <#void description#>
         @return <#return value description#>
         */
        OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressH264, (__bridge void * _Nullable)(self),&WEncodingSession);
        
        if (status != 0) {
            NSLog(@"H264: Unable to create a H264 session");
            return;
        }
        // VTSessionSetProperty接口设置帧率等属性
        // kVTCompressionPropertyKey_ProfileLevel : Specifies the profile and level for the encoded bitstream.
        //3、设置实时编码输出
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel);
        
        //4、设置帧率(每秒多少帧,如果帧率过低,会造成画面卡顿，大于16，人眼就识别不出来了)
        int fps = 30;
        CFNumberRef fpsRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &fps);
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_ExpectedFrameRate, fpsRef);
        
        //5、设置关键帧(GOPsize)间隔
        CFNumberRef frameIntervalRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &frameInterval);
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, frameIntervalRef);
        
        //6、设置码率(码率: 编码效率, 码率越高,则画面越清晰, 如果码率较低会引起马赛克 --> 码率高有利于还原原始画面,但是也不利于传输)
        //上限，单位是bps
        int bitRate = width * height * 3 * 4 * 8;
        CFNumberRef bitRateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRate);
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_AverageBitRate, bitRateRef);
        
        // 设置码率，均值，单位是byte
        int bitRateLimit = width * height * 3 * 4;
        CFNumberRef bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bitRateLimit);
        VTSessionSetProperty(WEncodingSession, kVTCompressionPropertyKey_DataRateLimits, bitRateLimitRef);
        
        //7、 Tell the encoder to start encoding 告诉编码器可以开始编码
        VTCompressionSessionPrepareToEncodeFrames(WEncodingSession);
    });
    
    // 视频编码保存的路径
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.h264"];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil]; // 移除旧文件
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]; // 创建新文件
    wFileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];  // 管理写进文件
    
    return WXResultNoErr;
}


- (WXResult)encode:(CVPixelBufferRef)pixelBuffer {
    
    // 1、帧时间, 如果不设置会导致时间轴过长，根据当前的帧数,创建CMTime的时间
    CMTime presentationTimeStamp = CMTimeMake(currentFrame++, 1000);
    
    // 使用硬编码接口VTCompressionSessionEncodeFrame来对该帧进行硬编码
    // 编码成功后，会自动调用session初始化时设置的回调函数
    //2、开始编码当前帧
        //有关编码操作的信息（例如：正在进行，帧被丢弃等）
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(WEncodingSession, pixelBuffer, presentationTimeStamp, kCMTimeInvalid, NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        VTCompressionSessionInvalidate(WEncodingSession);
        CFRelease(WEncodingSession);
        WEncodingSession = NULL;
        return WXResultFail;
    }
    NSLog(@"H264: VTCompressionSessionEncodeFrame Success : %d", (int)statusCode);

    return WXResultNoErr;
}


#pragma mark - 编码完成回调
/**
 *  h.264硬编码完成后回调 VTCompressionOutputCallback
 *  将硬编码成功的CMSampleBuffer转换成H264码流，通过网络传播
 *  解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组成NALU。将NALU发送出去。
 */
void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer) {
    
    NSLog(@"didCompressH264 called with status %d infoFlags %d", (int)status, (int)infoFlags);
    // 1.判断状态是否等于没有错误
    if (status != 0) {
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    //2.根据传入的参数获取对象
    WXVideoEncoder *encoder = (__bridge WXVideoEncoder *)(outputCallbackRefCon);
    
    // 3.判断是否是关键帧
    bool isKeyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    // 判断当前帧是否为关键帧 获取sps & pps 数据
    // 解析出参数集SPS和PPS，加上开始码后组装成NALU。提取出视频数据，将长度码转换成开始码，组成NALU。将NALU发送出去。
    if (isKeyframe) {
        //获取编码后的信息（存储于CMFormatDescriptionRef中）
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 获取SPS信息
        size_t sparameterSetSize, sparameterSetCount;
        const uint8_t *sparameterSet;
        OSStatus statusSPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                0,
                                                                                &sparameterSet,
                                                                                &sparameterSetSize,
                                                                                &sparameterSetCount,
                                                                                0);
        if (statusSPS == noErr) {
            // Found sps and now check for pps
            // pps
            size_t pparameterSetSize, pparameterSetCount;
            const uint8_t *pparameterSet;
            OSStatus statusPPS = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                    1,
                                                                                    &pparameterSet,
                                                                                    &pparameterSetSize,
                                                                                    &pparameterSetCount,
                                                                                    0);
            if (statusPPS == noErr) {
                
                // found sps pps
                NSData *sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
                NSData *pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
                if (encoder) {
                    [encoder gotSPS:sps withPPS:pps];
                }
            }
        }
    }
    // 编码后的图像，以CMBlockBuffe方式存储
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if (statusCodeRet == noErr) {
        
        size_t bufferOffSet = 0;
        // 返回的nalu数据前四个字节不是0001的startcode，而是帧长度length
        static const int AVCCHeaderLength = 4;
        /*
         //前四个字节存放内容查看
         NSData * redata = [[NSData alloc] initWithBytes:dataPointer length:AVCCHeaderLength];
         int result = 0;
         [redata getBytes:&result length:4];
         NSLog(@"前四个字节：%d",result);
         */
        // 循环获取nalu数据
        while (bufferOffSet < totalLength - AVCCHeaderLength) {
            
            uint32_t NALUUnitLength = 0;
            // Read the NAL unit length 读取NAL单元的长度
            memcpy(&NALUUnitLength, dataPointer + bufferOffSet, AVCCHeaderLength);
            //host Big－endian
            NALUUnitLength = CFSwapInt32BigToHost(NALUUnitLength);
            
            //读取到数据
            NSData *data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffSet + AVCCHeaderLength) length:NALUUnitLength];
            
            //写入文件
            [encoder gotEncodedData:data isKeyFrame:isKeyframe];
            
            //修改指针偏移量到下一个NAL unit区域
            // Move to the next NAL unit in the block buffer
            bufferOffSet += AVCCHeaderLength + NALUUnitLength;
        }
    }
}

#pragma mark - 编码完成写入h264文件中
- (void)gotSPS:(NSData *)sps withPPS:(NSData *)pps {
    
    NSLog(@"gotSPSAndPPS %d withPPS %d", (int)[sps length], (int)[pps length]);
    // 1.拼接NALU的header
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *byteHeader = [NSData dataWithBytes:bytes length:length];
    // 2.将NALU的头&NALU的体写入文件
    [wFileHandle writeData:byteHeader];
    [wFileHandle writeData:sps];
    [wFileHandle writeData:byteHeader];
    [wFileHandle writeData:pps];
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    
    NSLog(@"gotEncodedData %d", (int)[data length]);
    if (wFileHandle != NULL) {
        //帧头
        const char bytes[]= "\x00\x00\x00\x01";
        //字符串有隐式结尾"\0"
        size_t lenght = (sizeof bytes) - 1;
        NSData *byteHeader = [NSData dataWithBytes:bytes length:lenght];
        [wFileHandle writeData:byteHeader];
        [wFileHandle writeData:data];
    }
}

//停止编码
- (WXResult)endEncode {
    VTCompressionSessionCompleteFrames(WEncodingSession, kCMTimeInvalid);
    VTCompressionSessionInvalidate(WEncodingSession);
    CFRelease(WEncodingSession);
    WEncodingSession = NULL;
    
    return WXResultNoErr;
}

@end
