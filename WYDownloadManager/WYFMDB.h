//
//  WYFMDB.h
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WYMultitaskDloader;

@interface WYFMDB : NSObject

+ (void)insert:(WYMultitaskDloader *)download;
+ (void)update:(WYMultitaskDloader *)download;
+ (void)delete:(WYMultitaskDloader *)download;

+ (NSMutableArray *)query:(NSInteger)state;

@end
