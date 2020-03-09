//
//  LSStatisticsObject.h
//  LSMediaCapture
//
//  Created by taojinliang on 2017/11/16.
//  Copyright © 2017年 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSStatisticsObject : NSObject

/**
 视频发送帧率
 */
@property(nonatomic, assign) unsigned int videoSendFrameRate;

/**
 视频发送码率
 */
@property(nonatomic, assign) unsigned int videoSendBitRate;

/**
 视频发送分辨率的宽
 */
@property(nonatomic, assign) unsigned int videoSendWidth;

/**
 视频发送分辨率的高
 */
@property(nonatomic, assign) unsigned int videoSendHeight;

/**
 设置的视频帧率
 */
@property(nonatomic, assign) unsigned int videoSetFrameRate;

/**
 设置的视频码率
 */
@property(nonatomic, assign) unsigned int videoSetBitRate;

/**
 设置的分辨率宽
 */
@property(nonatomic, assign) unsigned int videoSetWidth;

/**
 设置的分辨率高
 */
@property(nonatomic, assign) unsigned int videoSetHeight;

/**
 音频的发送码率
 */
@property(nonatomic, assign) unsigned int audioSendBitRate;

/**
 视频编码一帧的时间
 */
@property(nonatomic, assign) unsigned int videoEncodeTime;

/**
 视频发送一帧的时间
 */
@property(nonatomic, assign) unsigned int videoMuxAndSendTime;

/**
 音频编码一帧的时间
 */
@property(nonatomic, assign) unsigned int audioEncodeTime;

/**
 音频发送一帧的时间
 */
@property(nonatomic, assign) unsigned int audioMuxAndSendTime;

/**
 如果卡顿累积了数据，则上报卡顿的平均耗时；否则上报非卡顿的平均耗时
 */
@property(nonatomic, assign) unsigned int writeFrameTime;

/**
 网络状况类型
 */
@property(nonatomic, assign) LS_QOSLVL_TYPE type;

/**
 视频发送缓存队列当前大小
 */
@property(nonatomic, assign) unsigned int videoSendBufferQueueCount;

/**
音频发送缓存队列当前大小
 */
@property(nonatomic, assign) unsigned int audioSendBufferQueueCount;
@end


/**
 自定义数据对象
 */
@interface LSCustomDataObject: NSObject

/**
 发送内容：长度控制在1600，默认为空
 */
@property(nonatomic, strong) NSString *sendConetnt;

/**
 发送间隔：表示隔interval帧发一帧自定义数据 ，最大50,默认为0
 如果为0，表示逐帧发送;如果是1，表示隔一帧发送一次;如果是5，表示隔5帧发送一次
 */
@property(nonatomic, assign) NSInteger sendInterval;

/**
 发送总次数：最大500，默认为10
 */
@property(nonatomic, assign) NSInteger sendTotalCites;
@end
