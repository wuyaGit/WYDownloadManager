//
//  WYSingletaskDloader.h
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WYSingletaskDloader : NSObject

/** 开始下载的位置（字节) */
@property(nonatomic, assign) long long begin;

/** 结束下载的位置（字节) */
@property(nonatomic, assign) long long end;

/** 请求路径 */
@property(nonatomic, strong) NSString *url;

/** 存放路径 */
@property(nonatomic, strong) NSString *filePath;

/** 当前下载量 */
@property(nonatomic, assign) long long currentLength;

/** 下载状态 */
@property(nonatomic, readonly, getter=isDownloading) BOOL downloading;

/** 更新进度block */
@property(nonatomic, copy) void(^progressHandler)(double progress);

/** 完成下载后block */
@property(nonatomic, copy) void(^didFinishHandler)(NSError *error);

- (void) startDownloading;
- (void) pauseDownloading;

@end
