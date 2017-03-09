//
//  PrefixHeader.h
//  WXH264Demo
//
//  Created by ABC on 17/3/8.
//  Copyright © 2017年 LYColud. All rights reserved.
//

#ifndef PrefixHeader_h
#define PrefixHeader_h


typedef enum {
    WXResultNoErr                                               = 0,
    //成功，无错误
    WXResultFail                                                = 1,
} WXResult;

/**
 *  视频采集分辨率
 */
typedef enum {
    WXCaptureCameraQuality352x288   = 0,
    //352*288
    WXCaptureCameraQuality640x480   = 1,
    //640*480
    WXCaptureCameraQuality960x540   = 2,
    //960*540
    WXCaptureCameraQuality1280x720  = 3,
    //1280*720
    WXCaptureCameraQuality1920x1080 = 4,
    //1920*1080
    WXCaptureCameraQuality3840x2160 = 5
    //3840*2160
} WXCaptureCameraQuality;


#endif /* PrefixHeader_h */
