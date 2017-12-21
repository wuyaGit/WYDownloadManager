//
//  DownloadTask.h
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadTask : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileId;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *multilineJson;
@property (nonatomic, copy) NSString *networkSpeed;
@property(nonatomic, assign) double progress;

@property(nonatomic, copy) void (^progressHandler)(double progress);
@property(nonatomic, copy) void (^successHandler)(NSString *url, NSString *filePath, NSError *error);

@end
