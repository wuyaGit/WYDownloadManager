//
//  WYMultitaskDloader.h
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WYDownloadState) {
    WYDownloadStateNo               = 0,            //未下载
    WYDownloadStateDown,                            //正在下载
    WYDownloadStatePause,                           //暂停
    WYDownloadStateDone                             //下载完成
};


//下载完成的通知名
static NSString *const WYDownloadTaskDidFinishedNotification = @"WYDownloadTaskDidFinishedNotification";

@interface WYMultitaskDloader : NSObject

/** 文件ID，一个标识符(没有id，可以使用url) */
@property(nonatomic, copy) NSString *fileId;

/** 请求路径 */
@property(nonatomic, copy) NSString *url;

/** 存放路径 */
@property(nonatomic, copy) NSString *filePath;

/** 线程下载进度值JSON */
@property(nonatomic, copy) NSString *multilineJson;

/** 下载速率 */
@property(nonatomic, copy) NSString *networkSpeed;

/** 下载状态 */
@property(nonatomic, assign) WYDownloadState state;

/** 下载进度 */
@property(nonatomic, assign) double progress;

/** 用来监听下载进度 */
@property(nonatomic, copy) void (^progressHandler)(double progress);

/** 用来监听下载成功 */
@property(nonatomic, copy) void (^successHandler)(NSString *fileId, NSString *filePath, NSError *error);

+ (instancetype)downloader;
- (instancetype)initWithParams:(NSDictionary *)params;

- (void) startDownloading;
- (void) pauseDownloading;
- (void) removeDownloading;
- (NSString *) getMultilineJson;

@end
