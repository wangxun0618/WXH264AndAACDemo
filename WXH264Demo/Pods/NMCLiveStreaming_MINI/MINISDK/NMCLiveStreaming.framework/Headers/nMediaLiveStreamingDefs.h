//
//  nMediaLiveStreamingDefs.h
//  livestream
//
//  Created by NetEase on 15/8/13.
//  Copyright (c) 2015年 NetEase. All rights reserved.
//

#ifndef livestream_nMediaLiveStreamingDefs_h
#define livestream_nMediaLiveStreamingDefs_h

//水印添加位置
typedef enum LSWaterMarkLocation{
    LS_WATERMARK_LOCATION_RECT,//由rect的origin定位置
    LS_WATERMARK_LOCATION_LEFTUP,
    LS_WATERMARK_LOCATION_LEFTDOWN,
    LS_WATERMARK_LOCATION_RIGHTUP,
    LS_WATERMARK_LOCATION_RIGHTDOWN,
    LS_WATERMARK_LOCATION_CENTER,
}LSWaterMarkLocation;

//因为滤镜很多款使用率非常低，所以将不再提供，只保留我们自主开发的几款新滤镜
typedef enum LSGpuImageFilterType{
    LS_GPUIMAGE_NORMAL,        //!< 无滤镜.
    LS_GPUIMAGE_SEPIA,         //!< 黑白
    LS_GPUIMAGE_ZIRAN,         //!< 自然
    LS_GPUIMAGE_MEIYAN1,       //!< 粉嫩
    LS_GPUIMAGE_MEIYAN2,       //!< 怀旧
} LSGpuImageFilterType;


//直播推流采集参数:摄像头采集方向
typedef enum LSCameraOrientation{
    LS_CAMERA_ORIENTATION_PORTRAIT,          //!< 摄像头采集方向.
    LS_CAMERA_ORIENTATION_UPDOWN,
    LS_CAMERA_ORIENTATION_RIGHT,
    LS_CAMERA_ORIENTATION_LEFT
}LSCameraOrientation;

//直播视频流质量
typedef enum LSVideoStreamingQuality{
    LS_VIDEO_QUALITY_LOW,           //!< 视频分辨率：低清 352*288.
    LS_VIDEO_QUALITY_MEDIUM,        //!< 视频分辨率：标清 480*360.
    LS_VIDEO_QUALITY_HIGH,          //!< 视频分辨率：高清 640*480.
    LS_VIDEO_QUALITY_SUPER,         //!< 视频分辨率：超清 960*540.
    LS_VIDEO_QUALITY_SUPER_HIGH,    //!< 视频分辨率：超高清 (1280*720).
    LS_VIDEO_QUALITY_SUPER_SUPER_HIGH,  //!< 视频分辨率：超超高清 (1920*1080).
}LSVideoStreamingQuality;

//摄像头类型
typedef enum LSCameraPosition{
    LS_CAMERA_POSITION_BACK,         //!< 后置摄像头.
    LS_CAMERA_POSITION_FRONT         //!< 前置摄像头.
} LSCameraPosition;

//视频显示模式
typedef enum LSVideoRenderScaleMode{
    LS_VIDEO_RENDER_MODE_SCALE_NONE, //!< 采集多大分辨率，则显示多大分辨率
    LS_VIDEO_RENDER_MODE_SCALE_16x9, //!< 无论采集多大分辨率，显示比例为16:9
}LSVideoRenderScaleMode;

//直播推流编码发送端参数
typedef enum LSHardWareEncEnable
{
    LS_HRD_NO,
    LS_HRD_AUDIO,
    LS_HRD_VIDEO,
    LS_HRD_AV
}LSHardWareEncEnable;

//推流协议
typedef enum LSOutputFormatType{
    LS_OUT_FMT_FLV,
    LS_OUT_FMT_RTMP,
}LSOutputFormatType;

//推流类型
typedef enum LSOutputStreamType{
    LS_HAVE_AUDIO,
    LS_HAVE_VIDEO,
    LS_HAVE_AV
}LSOutputStreamType;

//open a interface for application layer pass parameter
typedef enum LSMediaOption{
    LS_OPTION_FRAME_RATE,                 //!< 设置视频采集编码帧率: MAX_FRAME_RATE = 30,MIN_FRAME_RATE = 1
    LS_OPTION_BITRATE,                    //!< 设置视频编码码率
    LS_OPTION_TRACE_LEVEL,                //!< 设置log信息的输出级别
    LS_OPTION_TRACE_CALLBACK,             //!< 设置log信息的输出回调
    LS_OPTION_GET_STATISTICS,             //!< 得到统计直播推流统计信息
    LS_OPTION_STATISTICS_LOG_INTERVAL,    //!< 设置统计信息间隔
    LS_OPTION_MANUAL_SET_QUALITY,         //!< 设置手动切分辨率
    LS_OPTION_MANUAL_Real_QUALITY,        //!< 实际手动切分辨率
    LS_OPTION_FLV_RECORD,                 //!< flv录制
}LSMediaOption;


//日志级别
typedef enum LSMediaLog {
    LS_LOG_QUIET       = 0x00,          //!< log输出模式：不输出
    LS_LOG_ERROR       = 1 << 0,        //!< log输出模式：输出错误
    LS_LOG_WARNING     = 1 << 1,        //!< log输出模式：输出警告
    LS_LOG_INFO        = 1 << 2,        //!< log输出模式：输出信息
    LS_LOG_DEBUG       = 1 << 3,        //!< log输出模式：输出调试信息
    LS_LOG_DETAIL      = 1 << 4,        //!< log输出模式：输出详细
    LS_LOG_RESV        = 1 << 5,        //!< log输出模式：保留
    LS_LOG_LEVEL_COUNT = 6,
    LS_LOG_DEFAULT     = LS_LOG_WARNING    //!< log输出模式：默认输出警告
}LSMediaLog;

//Merge from error massage update
typedef enum LSErrorCode{
    LS_ERR_NO = 0,
    LS_ERR_ERROR,
    LS_ERR_PARAM,
    LS_ERR_CTX,
    LS_ERR_ALLOC,
    LS_ERR_CODEC_FOUND,
    LS_ERR_INIT,
    LS_ERR_CODEC_OPEN,
    LS_ERR_IO,
    LS_ERR_AGC_CREATE,
    LS_ERR_AGC_INIT,
    LS_ERR_AUDIO_PREPROCESS,
    LS_ERR_AUDIO_ENCODE,
    LS_ERR_AUDIO_PKT,
    LS_ERR_AUDIO_RELEASE,
    LS_ERR_VIDEO_ENCODE,
    LS_ERR_VIDEO_PKT,
    LS_ERR_VIDEO_RELEASE,
    LS_ERR_TRAILER,
    LS_ERR_OUT_MEDIA_FILEHEADER_WRONG,
    LS_ERR_HEADER_WAITING,
    LS_ERR_URL_INVALUE,
    LS_ERR_TO_STOP_LIVESTREAMING,
    LS_ERR_AVSYNC_TIME_OUT,
    LS_ERR_VIDEO_CROP_PARA_ILLEGAL
}LSErrorCode;//detail error massage

typedef enum LS_QOSLVL_TYPE
{
    LS_QOSLVL_HIGH = 1,
    LS_QOSLVL_MIDDLE = 2,
    LS_QOSLVL_LOW = 3
}LS_QOSLVL_TYPE;

//Qos场景区分
typedef enum LSVideoEncodeSceneType{
    LS_VIDEO_Fluency = 1,//流畅优先（优先降分辨率）
    LS_VIDEO_Resolution  //清晰优先 （优先降帧率）
}LSVideoEncodeSceneType;
#endif
