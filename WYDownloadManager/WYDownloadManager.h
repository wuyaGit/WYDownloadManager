//
//  WYDownloadManager.h
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WYMultitaskDloader.h"

@interface WYDownloadManager : NSObject

@property (nonatomic, strong) NSMutableArray *downloading;
@property (nonatomic, strong) NSMutableArray *downloaded;
@property (nonatomic, copy) NSString *dbPath;

+ (instancetype) sharedInstance;

#pragma mark - 下载任务的基本事件

/**
 *  开始下载
 *
 *  @param params 下载需要的参数 @{@"fileId":, @"url":, @"filePath":, @"multilineJson":}
 *  @param progressBlock 下载进度回调
 *  @param successBlock 下载完成回调
 *  @param completed 下载开始回调
 */
- (void)start:(NSDictionary *)params
progressBlock:(void (^)(double))progressBlock
 successBlock:(void (^)(NSString *, NSString *, NSError *))successBlock
    completed:(void (^)(void))completed;

/**
 *  开始下载
 *
 *  @param params 下载需要的参数 @{@"fileId":, @"url":, @"filePath":, @"multilineJson":}
 *  @param completed 下载开始回调
 */
- (void)start:(NSDictionary *)params completed:(void (^)(void))completed;

/**
 *  根据ID，暂停下载
 *
 *  @param fileId 下载任务Id
 *  @param completed 下载开始回调
 */
- (void)pause:(NSString *)fileId completed:(void (^)(void))completed;

/**
 *  根据ID，删除下载任务
 *
 *  @param fileId 下载任务Id
 *  @param completed 下载开始回调
 */
- (void)remove:(NSString *)fileId completed:(void (^)(void))completed;

#pragma mark - 执行全部下载事件
/**
 * 取消全部下载任务
 */
- (void)cancelAllTasks;
/**
 * 加载全部下载任务
 */
- (void)loadAll;

#pragma mark - 根据Id，获取下载任务的各种属性

/**
 * 根据ID，获取下载进度block
 */
- (void)multiProgressBlock:(NSString *)fileId block:(void (^)(double))block;

/**
 * 根据ID，获取下载成功block
 */
- (void)multiSuccessBlock:(NSString *)fileId block:(void (^)(NSString *, NSString *, NSError *))block;

/**
 * 根据ID，获取下载状态
 */
- (WYDownloadState)getDownloadStateForm:(NSString *)fileId;

/**
 * 根据ID，获取JSON值（JSON：暂停时候保存的状态值）
 */
- (NSString *)getMultilineJSONFrom:(NSString *)fileId;

/**
 * 根据ID，获取下载进度
 */
- (double)getMultiProgressFrom:(NSString *)fileId;

/**
 * 根据ID，获取下载速度
 */
- (NSString *)getNetworkSpeedFrom:(NSString *)fileId;

/**
 * 根据ID，获取下载路径
 */
- (NSString *)getCachePath:(NSString *)fileId;

@end
