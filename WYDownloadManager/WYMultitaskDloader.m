//
//  WYMultitaskDloader.m
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYMultitaskDloader.h"
#import "WYSingletaskDloader.h"

#define MaxMultilineCount 3

@interface WYMultitaskDloader()

/** 文件大小 */
@property(nonatomic, assign) long long fileSize;

/** 下载状态 */
@property(nonatomic, readonly, getter=isDownloading) BOOL downloading;

/** 单任务数组 */
@property(nonatomic, strong) NSMutableArray *singleDownloaders;

/** 最近日期 */
@property(nonatomic, strong) NSDate *lastDate;
/** 最近一次记录下载量 */
@property(nonatomic, assign) long long lastCompletedUnitCount;

@end

@implementation WYMultitaskDloader

#pragma mark - init

+ (instancetype)downloader {
    return [[[self class] alloc]init];
}

- (instancetype)initWithParams:(NSDictionary *)params {
    if (self = [super init]) {
        
    }
    
    self.fileId = params[@"fileId"];
    self.url = params[@"url"];
    self.filePath = params[@"filePath"];
    self.multilineJson = params[@"multilineJson"];
    
    return self;
}

#pragma mark - getter

- (NSMutableArray *)singleDownloaders {
    if (!_singleDownloaders) {
        _singleDownloaders = [NSMutableArray array];
        
        __weak __typeof(self) weakSelf = self;
        long long fileSize = self.fileSize;
        long long singleFileSize = 0; // 每条子线下载量
        if (fileSize % MaxMultilineCount == 0) {
            singleFileSize = fileSize / MaxMultilineCount;
        } else {
            singleFileSize = fileSize / MaxMultilineCount + 1;
        }
        
        if ([self isFirstDownloading]) {
            for (int i=0; i < MaxMultilineCount; i++) {
                WYSingletaskDloader *downloader = [[WYSingletaskDloader alloc] init];
                downloader.url = _url;
                downloader.filePath = _filePath;
                downloader.begin = i * singleFileSize;
                downloader.end = downloader.begin + singleFileSize - 1;
                downloader.progressHandler = ^(double progress){
                    NSLog(@"%d号单线下载器正在下载，下载进度:%f", i, progress);
                    [weakSelf getNetworkSpeed];
                };
                downloader.didFinishHandler = ^(NSError *error) {
                    if (error != nil) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:WYDownloadTaskDidFinishedNotification object:error userInfo:@{@"fileId":_fileId}];
                        
                        if (weakSelf.successHandler) {
                            weakSelf.successHandler(_fileId, _filePath, error);
                        }
                        [weakSelf pauseDownloading];
                    }else {
                        if ([weakSelf isFinished]) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:WYDownloadTaskDidFinishedNotification object:nil userInfo:@{@"fileId":_fileId}];
                            
                            if (weakSelf.successHandler) {
                                weakSelf.successHandler(_fileId, _filePath, nil);
                            }
                        }
                    }
                };
                
                [_singleDownloaders addObject:downloader];
            }
            
            // 创建临时文件，文件大小要跟实际大小一致
            // 1.创建一个0字节文件
            [[NSFileManager defaultManager] createFileAtPath:_filePath contents:nil attributes:nil];
            
            // 2.指定文件大小
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
            [fileHandle truncateFileAtOffset:fileSize];
        }
    }
    
    return _singleDownloaders;
}

#pragma mark - private methods

/** 获得文件大小 */
- (void) fileSize:(void(^)(void))completion {
    if (_fileSize == 0) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url]];
        request.HTTPMethod = @"HEAD";// 请求得到头响应
        
//        NSURLResponse *response = nil;
//        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        
        //建立连接并接收返回数据(异步执行)
        //NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            _fileSize = response.expectedContentLength;
            
            if (completion) {
                completion();
            }
        }];
        
    }else {
        if (completion) {
            completion();
        }
    }
}


/** 是否下载完成 */
- (BOOL) isFinished {
    BOOL isFinished = YES;
    for (WYSingletaskDloader *obj in _singleDownloaders) {
        if (obj.isDownloading) {
            isFinished = NO;
            break;
        }
    }
    
    return isFinished;
}

/** 是否第一次开始下载 */
- (BOOL) isFirstDownloading {
    __weak __typeof(self) weakSelf = self;
    long long fileSize = self.fileSize;
    long long singleFileSize = 0; // 每条子线下载量
    if (fileSize % MaxMultilineCount == 0) {
        singleFileSize = fileSize / MaxMultilineCount;
    } else {
        singleFileSize = fileSize / MaxMultilineCount + 1;
    }
    if ([_multilineJson isEqualToString:@""] || _multilineJson == nil) {
        
        return YES;
    }else {
        //解析json数据 例：{"begin":"currentLength", "begin":"currentLength", "begin":"currentLength"}，3个下载进度json值
        NSDictionary *array = [NSJSONSerialization JSONObjectWithData:[_multilineJson dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        
        for (NSString *key in array.allKeys) {
            WYSingletaskDloader *downloader = [[WYSingletaskDloader alloc] init];
            downloader.url = _url;
            downloader.filePath = _filePath;
            downloader.begin = [key longLongValue];
            downloader.end = downloader.begin + singleFileSize - 1;
            downloader.currentLength = [array[key] longLongValue];
            downloader.progressHandler = ^(double progress){
                NSLog(@"号单线下载器正在下载，下载进度:%f", progress);
                [weakSelf getNetworkSpeed];
            };
            downloader.didFinishHandler = ^(NSError *error) {
                if (error != nil) {
                    if (weakSelf.successHandler) {
                        weakSelf.successHandler(_fileId, _filePath, error);
                    }
                    [weakSelf pauseDownloading];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:WYDownloadTaskDidFinishedNotification object:error userInfo:@{@"fileId":_fileId}];
                }else {
                    if ([weakSelf isFinished]) {
                        if (weakSelf.successHandler) {
                            weakSelf.successHandler(_fileId, _filePath, nil);
                        }
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:WYDownloadTaskDidFinishedNotification object:nil userInfo:@{@"fileId":_fileId}];
                    }
                }
            };
            
            [_singleDownloaders addObject:downloader];
        }
        
        return NO;
    }
}

/** 计算下载总量 */
- (void) getNetworkSpeed {
    long long currentLength = 0;
    for (WYSingletaskDloader *obj in _singleDownloaders) {
        currentLength += obj.currentLength;
    }
    
    //计算下载进度
    float progress = (float)currentLength/self.fileSize;
    self.progress = progress;
    if (self.progressHandler) {
        self.progressHandler(progress);
    }
    
    [self reloadNetworkSpeed: currentLength];
}

/** json化各线程进度，便于保存 */
- (void)reloadNetworkSpeed:(long long)currentLength {
    //计算时间差
    double diffSecond = [self sinceExpireDate:_lastDate];
    //最近一次记录的下载总量为0，是第一次开始计算，初始化最近一次记录的下载总量和时间
    if (_lastCompletedUnitCount == 0) {
        _lastCompletedUnitCount = currentLength;
        _lastDate = [NSDate date];
    }
    
    //在时间大于1秒，且最近记录的下载总量大于0，开始计算下载速率
    if (diffSecond >= 1.0 && _lastCompletedUnitCount > 0) {
        NSInteger diffCount = currentLength - _lastCompletedUnitCount;
        _networkSpeed = [self convertSize:diffCount/diffSecond];
        
        _lastCompletedUnitCount = currentLength;
        _lastDate = [NSDate date];
    }
}

#pragma mark - tool methods

/** json化各线程进度，便于保存 */
- (double)sinceExpireDate:(NSDate *)expireDate {
    NSDate *nowDate = [NSDate date];
    
    UInt64 msecond1 = [nowDate timeIntervalSince1970]*1000;
    UInt64 msecond2 = [expireDate timeIntervalSince1970]*1000;
    
    return (double)(msecond1 - msecond2)/1000.0;
}

/** json化各线程进度，便于保存 */
- (NSString *)convertSize:(NSInteger)fileSize {
    NSString *sizeStr;
    if (fileSize <= 0) {
        sizeStr = @"0.00KB";
    }else{
        if ((double)fileSize/1024/1024/1024 >= 1) {
            sizeStr = [NSString stringWithFormat:@"%.2fG/s",(double)fileSize/1024/1024/1024];
        }else if ((double)fileSize/1024/1024 >= 1) {
            sizeStr = [NSString stringWithFormat:@"%.2fMB/s",(double)fileSize/1024/1024];
        }else if ((double)fileSize/1024 >= 1){
            sizeStr = [NSString stringWithFormat:@"%.2fKB/s",(double)fileSize/1024];
        }else{
            sizeStr = [NSString stringWithFormat:@"%.2fB/s",(double)fileSize];
        }
    }
    return sizeStr;
}

/**
 *  获取系统可用存储空间
 */
- (NSUInteger)systemFreeSpace{
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSDictionary *dict=[[NSFileManager defaultManager] attributesOfFileSystemForPath:docPath error:nil];
    return [[dict objectForKey:NSFileSystemFreeSize] integerValue];
}

#pragma mark - public methods

/** 开始下载 */
- (void)startDownloading {
    NSUInteger freeSpace = [self systemFreeSpace];
    if(freeSpace < 1024*1024*20){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"系统可用存储空间不足20M" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirm=[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:confirm];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    [self fileSize:^{
        [self.singleDownloaders makeObjectsPerformSelector:@selector(startDownloading)];
        
        _downloading = YES;
        NSLog(@"多线程下载开始");
    }];
}

/** 暂停下载 */
- (void)pauseDownloading {
    [self.singleDownloaders makeObjectsPerformSelector:@selector(pauseDownloading)];
    _downloading = NO;
    NSLog(@"多线程下载暂停!");
}

/** 删除下载 */
- (void)removeDownloading {
    [_singleDownloaders removeAllObjects];
    _singleDownloaders = nil;
    _downloading = NO;
    NSLog(@"删除下载器");
}

/** json化各线程进度，便于保存 */
- (NSString *)getMultilineJson {
    
    NSMutableDictionary *jsData = [NSMutableDictionary dictionaryWithCapacity:MaxMultilineCount];
    [_singleDownloaders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WYSingletaskDloader *singleDownloader = (WYSingletaskDloader *)obj;
        [jsData setObject:@(singleDownloader.currentLength) forKey:[NSString stringWithFormat:@"%@", @(singleDownloader.begin)]];
    }];
    
    if (jsData.count == 0) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsData options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
