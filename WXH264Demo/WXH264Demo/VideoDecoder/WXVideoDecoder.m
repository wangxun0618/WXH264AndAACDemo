//
//  WXVideoDecoder.m
//  WXH264Demo
//
//  Created by ABC on 17/3/9.
//  Copyright © 2017年 LYColud. All rights reserved.
//

/*
 1>CVPixelBuffer：编码前和解码后的图像数据结构。
 2>CMTime、CMClock和CMTimebase：时间戳相关。时间以64-bit/32-bit的形式出现。
 3>CMBlockBuffer：编码后，结果图像的数据结构。
 4>CMVideoFormatDescription：图像存储方式，编解码器等格式描述。
 5>CMSampleBuffer：存放编解码前后的视频图像的容器数据结构。
 6>stratCode: "\x00\x00\x00\x01"
 */

/*
 PPS（Picture Parameter Sets）：图像参数集
 SPS（Sequence Parameter Set）：序列参数集
 */

/*
 _____________________________________________
 |startCode | sps | pps |  图像信息(IBP及其他信息)  |
 ￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
 */


#import "WXVideoDecoder.h"

const uint8_t startCode[4] = {0,0,0,1};

@interface WXVideoDecoder ()

//文件输入流
@property (nonatomic, strong) NSInputStream *inputStream;

//解码后的回调
@property (nonatomic, copy) VideoDecodeCompleteBlock completeBlock;

@end

@implementation WXVideoDecoder{
    //帧
    NALUnit frame_buffer;
    
    //sps
    NALUnit sps_buffer;
    
    //pps
    NALUnit pps_buffer;
    
    uint8_t *_buffer;
    long _bufferSize;
    long _maxSize;
    
    //解码会话
    VTDecompressionSessionRef wx_decodeSession;
    //描述
    CMFormatDescriptionRef  wx_formatDescription;
    
}

- (WXResult)decodeWithPath:(NSString *)path complete:(VideoDecodeCompleteBlock)complete{
    self.completeBlock = [complete copy];
    self.inputStream = [NSInputStream inputStreamWithFileAtPath:path];
    [self.inputStream open];
    
    _bufferSize = 0;
    _maxSize = 10000*1000;
    _buffer = malloc(_maxSize);
    
    //循环读取
    while (true) {
        //读数据
        if ([self readStream] == NO) {
            NSLog(@"播放结束");
            break;
        }
        
        //转换
        uint32_t nalSize = (uint32_t)(frame_buffer.size - 4);
        uint32_t *pNalSize = (uint32_t *)frame_buffer.data;
        *pNalSize = CFSwapInt32HostToBig(nalSize);
        
        //存放像素信息
        CVPixelBufferRef pixelBuffer = NULL;
        //NAL的类型(startCode后的第一个字节的后5位)
        int NAL_type = frame_buffer.data[4] & 0x1f;
        switch (NAL_type) {
            case 0x5:
                NSLog(@"Nal type is IDR frame");
                if (!wx_decodeSession){
                    [self setupDecodeSession];
                }
                pixelBuffer = [self decode];
                break;
            case 0x7:
                NSLog(@"Nal type is SPS");
                //从帧中获取sps信息
                sps_buffer.size = frame_buffer.size-4;
                if (!sps_buffer.data){
                    sps_buffer.data = malloc(sps_buffer.size);
                }
                memcpy(sps_buffer.data, frame_buffer.data+4, sps_buffer.size);
                break;
            case 0x8:
                NSLog(@"Nal type is PPS");
                //从帧中获取sps信息
                pps_buffer.size = frame_buffer.size-4;
                if (!pps_buffer.data){
                    pps_buffer.data = malloc(pps_buffer.size);
                }
                memcpy(pps_buffer.data, frame_buffer.data+4, pps_buffer.size);
                break;
            default:
                //图像信息
                NSLog(@"Nal type is B/P frame or another");
                pixelBuffer = [self decode];
                break;
        }
        if (pixelBuffer) {
            NSLog(@">>> %@",pixelBuffer);

            //同步保证数据信息不释放
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (self.completeBlock){
                    self.completeBlock(pixelBuffer);
                }
            });
            CVPixelBufferRelease(pixelBuffer);
        }
    }
    return WXResultNoErr;
}

//解码会话
- (void)setupDecodeSession{
    const uint8_t * const paramSetPointers[2] = {sps_buffer.data,pps_buffer.data};
    const size_t paramSetSize[2] = {sps_buffer.size,pps_buffer.size};
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, paramSetPointers, paramSetSize, 4, &wx_formatDescription);
    
    if (status == noErr){
        CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
        //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        //结束后的回调
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        //填入null，videottoolbox选择解码器
        status = VTDecompressionSessionCreate(kCFAllocatorDefault, wx_formatDescription, NULL, attrs, &callBackRecord, &wx_decodeSession);
        
        if (status!=noErr){
            NSLog(@"解码会话创建失败");
        }
        CFRelease(attrs);
    }else {
        NSLog(@"创建FormatDescription失败");
    }
}

- (BOOL)readStream{
    
    if (_bufferSize<_maxSize && self.inputStream.hasBytesAvailable) {
        //正数：读取的字节数，0：读取到尾部，-1：读取错误
        NSInteger readSize = [self.inputStream read:_buffer+_bufferSize maxLength:_maxSize-_bufferSize];
        _bufferSize += readSize;
    }
    //对比buffer的前四位是否是startCode(每一帧前都有startCode)，并且数据长度需要大于startCode
    if (memcmp(_buffer, startCode, 4) == 0 && _bufferSize > 4){
        //buffer的起始和结束位置
        uint8_t *startPoint = _buffer + 4;
        uint8_t *endPoint = _buffer + _bufferSize;
        while (startPoint != endPoint) {
            //获取当前帧长度（通过获取到下一个0x00000001,来确定）
            if (memcmp(startPoint, startCode, 4) == 0){
                //找到下一帧，计算帧长
                frame_buffer.size = (unsigned int)(startPoint - _buffer);
                //置空帧
                if (frame_buffer.data){
                    free(frame_buffer.data);
                    frame_buffer.data = NULL;
                }
                frame_buffer.data = malloc(frame_buffer.size);
                //从缓冲区内复制当前帧长度的信息赋值给帧
                memcpy(frame_buffer.data, _buffer, frame_buffer.size);
                //缓冲区中数据去掉帧数据（长度减少，地址移动）
                memmove(_buffer, _buffer+frame_buffer.size, _bufferSize-frame_buffer.size);
                _bufferSize -= frame_buffer.size;
                
                return YES;
            }else{
                //如果不是，移动指针
                startPoint++;
            }
        }
    }
    return NO;
}

//解码
- (CVPixelBufferRef)decode {
    CVPixelBufferRef outputPixelBuffer = NULL;
    //视频图像数据
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)frame_buffer.data,
                                                          frame_buffer.size,
                                                          kCFAllocatorNull,
                                                          NULL,
                                                          0,
                                                          frame_buffer.size,
                                                          0,
                                                          &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {frame_buffer.size};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           wx_formatDescription ,
                                           1,
                                           0,
                                           NULL,
                                           1,
                                           sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(wx_decodeSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    free(frame_buffer.data);
    frame_buffer.data = NULL;
    return outputPixelBuffer;
}

- (WXResult)destroy {
    
    if (wx_decodeSession) {
        VTDecompressionSessionInvalidate(wx_decodeSession);
        CFRelease(wx_decodeSession);
        wx_decodeSession = NULL;
    }
    if (wx_formatDescription) {
        CFRelease(wx_formatDescription);
        wx_formatDescription = NULL;
    }
    
    return WXResultNoErr;
}


//解码回调结束 （使用VTDecompressionSessionDecodeFrameWithOutputHandler，直接接受处理结果）
static void didDecompress(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef*)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
}


@end
