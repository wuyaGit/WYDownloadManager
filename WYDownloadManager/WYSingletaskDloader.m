//
//  WYSingletaskDloader.m
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYSingletaskDloader.h"

@interface WYSingletaskDloader()

/** 文件句柄 */
@property(nonatomic, strong) NSFileHandle *handle;

/** 当前下载连接 */
@property(nonatomic, strong) NSURLConnection *conn;

@end

@implementation WYSingletaskDloader

/** 初始化文件句柄 */
- (NSFileHandle *)handle {
    if (nil == _handle) {
        _handle = [NSFileHandle fileHandleForWritingAtPath:self.filePath];
    }
    return _handle;
}

/** 开始下载 */
- (void) startDownloading {
//    NSString *url = [self.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // 从上次下载完成的地方继续下载，初始就是0
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    
    // 设置request头信息，指明要从文件哪里开始下载
    NSString *value = [NSString stringWithFormat:@"bytes=%lld-%lld", self.begin + self.currentLength, self.end];
    [request setValue:value forHTTPHeaderField:@"Range"];
    
    self.conn = [NSURLConnection connectionWithRequest:request delegate:self];
    
    _downloading = YES;
}

/** 暂停下载 */
- (void) pauseDownloading {
    //  取消连接，不能恢复
    [self.conn cancel];
    self.conn = nil;
    
    _downloading = NO;
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"失败");
    NSLog(@"%@", error);
    
    _downloading = NO;
    if (self.didFinishHandler) {
        self.didFinishHandler(error);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"开始接收");
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // 移动句柄到上次写入数据的末位置
    [self.handle seekToFileOffset:self.begin + self.currentLength];
    
    // 写入数据
    [self.handle writeData:data];
    
    // 已经下载的量
    self.currentLength += data.length;
    
    if (self.progressHandler) {
        double progress = (double)self.currentLength / (self.end - self.begin + 1);
        self.progressHandler(progress);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"接收完毕");
    
    // 清空下载量
    //    self.currentLength = 0;
    
    // 关闭连接
    [self.handle closeFile];
    self.handle = nil;
    _downloading = NO;
    
    if (self.didFinishHandler) {
        self.didFinishHandler(nil);
    }
}


@end
