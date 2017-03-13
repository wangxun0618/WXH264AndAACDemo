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
 */

/*
 PPS（Picture Parameter Sets）：图像参数集
 SPS（Sequence Parameter Set）：序列参数集
 */

/*
 ________________________________________________
 |startCode | sps | pps |  图像信息(IBP及其他信息)  |
 ￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣￣
 */

#import "WXVideoDecoder.h"

@implementation WXVideoDecoder
{
    VTDecompressionSessionRef wx_decodeSession; //解码
    CMFormatDescriptionRef  wx_formatDescription;
    
    NALUnit dataUnit;
    
    NALUnit spsUnit;
    
    NALUnit ppsUnit;
    
    //帧
    uint8_t *frame_buffer;
    long frame_size;
    
    //sps
    uint8_t *sps_buffer;
    long sps_size;
    
    //pps
    uint8_t *pps_buffer;
    long pps_size;
}

- (WXResult)create {
    if (!wx_decodeSession) {
        
        //sps和pps数据是不包含“00 00 00 01”的start code；
        
        NSLog(@" >>> spsUnit: %02x %02x",spsUnit.data[0],spsUnit.data[1]);
        NSLog(@" >>> ppsUnit: %02x %02x %02x %02x",ppsUnit.data[0],ppsUnit.data[1],ppsUnit.data[2],ppsUnit.data[3]);
        
        // 把SPS和PPS包装成CMVideoFormatDescription
        const uint8_t *parameterSetPointers[2] = {spsUnit.data,ppsUnit.data};
        
        
        const size_t parameterSetSizes[2] ={spsUnit.size,ppsUnit.size};
        OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                              2, // param count
                                                                              parameterSetPointers, parameterSetSizes,
                                                                              4, // nal start code size
                                                                             &wx_formatDescription);
        if (status == noErr) {
            const void *keys[] = {kCVPixelBufferPixelFormatTypeKey};
            //kCVPixelFormatType_420YpCbCr8Planar is YUV420,
            //kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
            uint32_t biPlanarType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &biPlanarType)};
            CFDictionaryRef attributes = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
            //Create decompression session
            VTDecompressionOutputCallbackRecord outputCallBaclRecord;
            outputCallBaclRecord.decompressionOutputRefCon = NULL;
            outputCallBaclRecord.decompressionOutputCallback = didDecompressOutputCallback;
            status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                  wx_formatDescription,
                                                  NULL, attributes,
                                                  &outputCallBaclRecord,
                                                  &wx_decodeSession);
            CFRelease(attributes);
        }else{
            
            NSLog(@"Error code %d:Creates a format description for a video media stream described by H.264 parameter.", (int)status);
            return WXResultFail;
        }
    }
    return WXResultNoErr;
}

- (CVPixelBufferRef)wx_decodeWithData:(NALUnit)buffer {
    
    int NAL_type = buffer.data[0] & 0x1f;
    switch (NAL_type) {
        case 0x05:
            NSLog(@"Nal type is IDR frame");
            break;
        case 0x07:
            NSLog(@"Nal type is SPS");
            break;
        case 0x08:
            NSLog(@"Nal type is PPS ");
            break;
        case 0x01:
            NSLog(@"Nal type is B/P frame or another");
            break;
    }
    
    if (buffer.type == 1) {
        spsUnit.data = buffer.data;
        spsUnit.type = buffer.type;
        spsUnit.size = buffer.size;
        return nil;
    } else if (buffer.type == 2) {
        ppsUnit.data = buffer.data;
        ppsUnit.type = buffer.type;
        ppsUnit.size = buffer.size;
        return nil;
    } else if (buffer.type == 3) {
//        const char bytes[]= "\x00\x00";
//        dataUnit.data = malloc(buffer.size + 2);
//        memcpy(dataUnit.data, bytes, 2);
//        memcpy(dataUnit.data+2, buffer.data, buffer.size);
        dataUnit.data = buffer.data;
        dataUnit.type = buffer.type;
        dataUnit.size = buffer.size;
        [self create];
    }
    
    NSLog(@">>> type = %d, size = %d data = %02x %02x %02x %02x %02x %02x %02x %02x",dataUnit.type,dataUnit.size,dataUnit.data[0],dataUnit.data[1],dataUnit.data[2],dataUnit.data[3],dataUnit.data[4],dataUnit.data[5],dataUnit.data[6],dataUnit.data[7]);
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    if (wx_decodeSession) {
        // 用CMBlockBuffer把NALUnit包装起来
        CMBlockBufferRef blockBuffer = NULL;
        OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                             dataUnit.data,
                                                             dataUnit.size,
                                                             kCFAllocatorNull,
                                                             NULL,
                                                             0,
                                                             dataUnit.size,
                                                             0,
                                                             &blockBuffer);
        
        int reomveHeaderSize = dataUnit.size - 4;
        const uint8_t sourceBytes[] = {(uint8_t)(reomveHeaderSize >> 24), (uint8_t)(reomveHeaderSize >> 16), (uint8_t)(reomveHeaderSize >> 8), (uint8_t)reomveHeaderSize};
        status = CMBlockBufferReplaceDataBytes(sourceBytes, blockBuffer, 0, 4);
        NSLog(@"BlockBufferReplace: %@", (status == kCMBlockBufferNoErr) ? @"successfully." : @"failed.");
        
        //2.Create CMSampleBuffer
        if(status == kCMBlockBufferNoErr){
            CMSampleBufferRef sampleBufferRef = NULL;
            const size_t sampleSizes[] = {dataUnit.size};
            OSStatus createStatus = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                                              blockBuffer,
                                                              wx_formatDescription,
                                                              1,
                                                              0,
                                                              NULL,
                                                              1,
                                                              sampleSizes,
                                                              &sampleBufferRef);
            //3.Create CVPixelBuffer
            if(createStatus == kCMBlockBufferNoErr && sampleBufferRef){
                VTDecodeFrameFlags frameFlags = 0;
                VTDecodeInfoFlags infoFlags = 0;
                // 默认是同步操作->会调用didDecompress，再回调
                // outputPixelBuffer 开始解码

                OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(wx_decodeSession,
                                                                          sampleBufferRef,
                                                                          frameFlags,
                                                                          &outputPixelBuffer,
                                                                          &infoFlags);
                if(decodeStatus == kVTInvalidSessionErr){
                    NSLog(@"Invalid session, reset decompression session.");
                }else if(decodeStatus == kVTVideoDecoderBadDataErr){
                    NSLog(@"Generate bad data.");
                }else if(decodeStatus != noErr){
                    NSLog(@"Decompress data failed.status = %d",decodeStatus);
                }
                CFRelease(sampleBufferRef);
            }
            CFRelease(blockBuffer);
        }
    }
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
    free(sps_buffer);
    free(sps_buffer);
    
    return WXResultNoErr;
}

#pragma mark - 解码完成回调 回调didDecompressOutputCallback
void didDecompressOutputCallback(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef imageBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ) {
    
    NSLog(@">>> 解码回调 = %d",status);
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef*)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
}

@end
