# WXH264AndAACDemo
这套硬解码API是几个纯C函数，在任何OC或者 C++代码里都可以使用。

首先要把 VideoToolbox.framework 添加到工程里，并且包含以下头文件。

include <VideoToolbox/VideoToolbox.h>

解码主要需要以下三个函数

VTDecompressionSessionCreate 创建解码 session

VTDecompressionSessionDecodeFrame 解码一个frame

VTDecompressionSessionInvalidate 销毁解码 session

首先要创建 decode session，方法如下：

```Objective-C
OSStatus status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &deocderSession);
```

其中 decoderFormatDescription 是 CMVideoFormatDescriptionRef 类型的视频格式描述，这个需要用H.264的 sps 和 pps数据来创建，调用以下函数创建 decoderFormatDescription

CMVideoFormatDescriptionCreateFromH264ParameterSets

需要注意的是，这里用的 sps和pps数据是不包含“00 00 00 01”的start code的。

attr是传递给decode session的属性词典

```Objective-C
CFDictionaryRef attrs = NULL;
        const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
// kCVPixelFormatType_420YpCbCr8Planar is YUV420
// kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL)
```

其中重要的属性就一个，kCVPixelBufferPixelFormatTypeKey，指定解码后的图像格式，必须指定成NV12，苹果的硬解码器只支持NV12。

callBackRecord 是用来指定回调函数的，解码器支持异步模式，解码后会调用这里的回调函数。

如果 decoderSession创建成功就可以开始解码了。

```Objective-C
VTDecodeFrameFlags flags = 0;
            //kVTDecodeFrame_EnableTemporalProcessing | kVTDecodeFrame_EnableAsynchronousDecompression;
            VTDecodeInfoFlags flagOut = 0;
            CVPixelBufferRef outputPixelBuffer = NULL;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
```

其中 flags 用0 表示使用同步解码，这样比较简单。 其中 sampleBuffer是输入的H.264视频数据，每次输入一个frame。 先用CMBlockBufferCreateWithMemoryBlock 从H.264数据创建一个CMBlockBufferRef实例。 然后用 CMSampleBufferCreateReady创建CMSampleBufferRef实例。 这里要注意的是，传入的H.264数据需要Mp4风格的，就是开始的四个字节是数据的长度而不是“00 00 00 01”的start code，四个字节的长度是big-endian的。 一般来说从 视频里读出的数据都是 “00 00 00 01”开头的，这里需要自己转换下。

解码成功之后，outputPixelBuffer里就是一帧 NV12格式的YUV图像了。 如果想获取YUV的数据可以通过

```
CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(outputPixelBuffer);
```
获得图像数据的指针，需要说明baseAddress并不是指向YUV数据，而是指向一个CVPlanarPixelBufferInfo_YCbCrBiPlanar结构体，结构体里记录了两个plane的offset和pitch。

但是如果想把视频播放出来是不需要去读取YUV数据的，因为CVPixelBufferRef是可以直接转换成OpenGL的Texture或者UIImage的。

调用CVOpenGLESTextureCacheCreateTextureFromImage，可以直接创建OpenGL Texture

从 CVPixelBufferRef 创建 UIImage

```
CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    UIImage *uiImage = [UIImage imageWithCIImage:ciImage];
```

解码完成后销毁 decoder session

```
VTDecompressionSessionInvalidate(deocderSession)
```
