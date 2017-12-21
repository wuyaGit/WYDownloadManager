//
//  WYDownloadManager.m
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYDownloadManager.h"
#import "WYFMDB.h"

/**
 *  最大同时下载任务数，超过将自动存入排队对列中
 */
#define kWYDwonloadMaxTaskCount 3


@implementation WYDownloadManager

#pragma mark - init

+ (instancetype)sharedInstance {
    static WYDownloadManager *instance = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        instance = [[WYDownloadManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    
    self.downloaded = [[NSMutableArray alloc] init];
    self.downloading = [[NSMutableArray alloc] init];
    
    //注册程序下载完成的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskDidFinishDownloading:) name:WYDownloadTaskDidFinishedNotification object:nil];
    //注册程序即将被终结的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskWillBeTerminate:) name: UIApplicationWillTerminateNotification object:nil];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)downloadTaskDidFinishDownloading:(NSNotification *)sender {
    [self dbFinished:sender];
}

- (void)downloadTaskWillBeTerminate:(NSNotification *)sender {
    [self cancelAllTasks];
}

#pragma mark - public methods

- (void)start:(NSDictionary *)params
progressBlock:(void (^)(double))progressBlock
 successBlock:(void (^)(NSString *, NSString *, NSError *))successBlock
    completed:(void (^)(void))completed {
    [self start:params completed:^(){
        WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:params[@"fileId"]];
        downloader.progressHandler = progressBlock;
        downloader.successHandler = successBlock;
    }];
    
    if (completed) {
        completed();
    }
}

- (void)start:(NSDictionary *)params completed:(void (^)(void))completed {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:params[@"fileId"]];
    if (downloader == nil) {
        downloader = [[WYMultitaskDloader alloc] initWithParams:params];
        //添加到数据库
        [self dbStart:downloader];
    }
    
    [self dbUpdate:params[@"fileId"] state:WYDownloadStateDown];
    
    [downloader startDownloading];
    
    if (completed) {
        completed();
    }
}

- (void)pause:(NSString *)fileId completed:(void (^)(void))completed {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (downloader) {
        [downloader pauseDownloading];
    }
    
    //更新数据库
    [self dbUpdate:fileId state:WYDownloadStatePause];
    //保存下载状态JSON
    [self dbUpdate:fileId multilineJson:[downloader getMultilineJson]];
    
    if (completed) {
        completed();
    }
}

- (void)remove:(NSString *)fileId completed:(void (^)(void))completed {
    // 暂停下载
    if ([self getMultiDownloaderInDownloading:fileId] || [self getMultiDownloaderInDownloaded:fileId]) {
        WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
        if (downloader) {
            [downloader pauseDownloading];
        }else {
            downloader = [self getMultiDownloaderInDownloaded:fileId];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:downloader.filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:downloader.filePath error:nil];
        }
    }
    //更新数据库
    [self dbDelete:fileId];
    
    if (completed) {
        completed();
    }
}

#pragma mark -

- (void)cancelAllTasks {
    // 暂停所有下载
    [_downloading enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WYMultitaskDloader *downloader = (WYMultitaskDloader *)obj;
        [downloader pauseDownloading];
        
        //更新数据库
        [self dbUpdate:downloader.fileId state:WYDownloadStatePause];
        [self dbUpdate:downloader.fileId multilineJson:[downloader getMultilineJson]];
    }];
}

- (void)loadAll {
    //加载全部暂停的下载
    [_downloading removeAllObjects];
    NSArray *array = [WYFMDB query:WYDownloadStatePause];
    [_downloading addObjectsFromArray:array];
    
    //加载全部完成的下载
    [_downloaded removeAllObjects];
    array = [WYFMDB query:WYDownloadStateDone];
    [_downloaded addObjectsFromArray:array];
}

#pragma mark -

- (void)multiProgressBlock:(NSString *)fileId block:(void (^)(double))block {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    downloader.progressHandler = block;
}

- (void)multiSuccessBlock:(NSString *)fileId block:(void (^)(NSString *, NSString *, NSError *))block {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    downloader.successHandler = block;
}

- (WYDownloadState)getDownloadStateForm:(NSString *)fileId {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (!downloader) {
        downloader = [self getMultiDownloaderInDownloaded:fileId];
    }
    return downloader.state;
}

- (NSString *)getMultilineJSONFrom:(NSString *)fileId {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (!downloader) {
        downloader = [self getMultiDownloaderInDownloaded:fileId];
    }
    if (!downloader) {
        return @"";
    }
    return [downloader getMultilineJson];
}

- (double)getMultiProgressFrom:(NSString *)fileId {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (!downloader) {
        downloader = [self getMultiDownloaderInDownloaded:fileId];
    }
    return downloader.progress;
}

- (NSString *)getNetworkSpeedFrom:(NSString *)fileId {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    return downloader.networkSpeed;
}

- (NSString *)getCachePath:(NSString *)fileId {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (!downloader) {
        downloader = [self getMultiDownloaderInDownloaded:fileId];
    }
    return downloader.filePath;
}

#pragma mark - private methods

- (WYMultitaskDloader *)getMultiDownloaderInDownloading:(NSString *)fileId {
    __block NSInteger index = -1;
    [_downloading enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WYMultitaskDloader *dObj = (WYMultitaskDloader *)obj;
        if ([fileId isEqualToString:dObj.fileId]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index != -1) {
        return _downloading[index];
    }
    
    return nil;
}

- (WYMultitaskDloader *)getMultiDownloaderInDownloaded:(NSString *)fileId {
    __block NSInteger index = -1;
    [_downloaded enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WYMultitaskDloader *dObj = (WYMultitaskDloader *)obj;
        if ([fileId isEqualToString:dObj.fileId]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index != -1) {
        return _downloaded[index];
    }
    
    return nil;
}

#pragma mark - db methods

- (void)dbStart:(WYMultitaskDloader *)downloader {
    [_downloading addObject:downloader];
    [WYFMDB insert:downloader];
}

- (void)dbUpdate:(NSString *)fileId state:(WYDownloadState)state {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (downloader) {
        downloader.state = state;
        [WYFMDB update:downloader];
    }
}

- (void)dbUpdate:(NSString *)fileId multilineJson:(NSString *)multilineJson {
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
    if (downloader) {
        downloader.multilineJson = multilineJson;
        [WYFMDB update:downloader];
    }
}

- (void)dbDelete:(NSString *)fileId {
    if ([self getMultiDownloaderInDownloading:fileId] || [self getMultiDownloaderInDownloaded:fileId]) {
        WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:fileId];
        if (downloader) {
            [_downloading removeObject:downloader];
        }else {
            downloader = [self getMultiDownloaderInDownloaded:fileId];
            [_downloaded removeObject:downloader];
        }
        
        [WYFMDB delete:downloader];
    }
}

- (void)dbFinished:(NSNotification *)sender {
    NSError *error = sender.object;
    WYMultitaskDloader *downloader = [self getMultiDownloaderInDownloading:sender.userInfo[@"fileId"]];
    
    if (error) {
        [self dbUpdate:downloader.fileId state:WYDownloadStatePause];
        [self dbUpdate:downloader.fileId multilineJson:[downloader getMultilineJson]];
    }else {
        [self dbUpdate:downloader.fileId state:WYDownloadStateDone];
        [self dbUpdate:downloader.fileId multilineJson:[downloader getMultilineJson]];
        
        [_downloading removeObject:downloader];
        [_downloaded addObject:downloader];
    }
}

@end
