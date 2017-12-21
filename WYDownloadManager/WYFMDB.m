//
//  WYFMDB.m
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "WYFMDB.h"
#import <FMDB/FMDB.h>

#import "WYDownloadManager.h"
#import "WYMultitaskDloader.h"

@implementation WYFMDB

#pragma mark - create db

+ (FMDatabase *)createDB {
    NSString *path = [WYDownloadManager sharedInstance].dbPath;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    path = [path stringByAppendingPathComponent:@"WYDOWNLOADDB.db"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if ([db open]) {
            NSString *sqlCreateTb = @"CREATE TABLE DOWNLOAD (ID INTEGER PRIMARY KEY AUTOINCREMENT, FILEID TEXT, URL TEXT, FILEPATH TEXT, MUTILINEJSON TEXT, STATE INTEGER, PROGRESS INTEGER)";
            
            BOOL res = [db executeUpdate:sqlCreateTb];
            if (!res) {
                NSLog(@"error when creating db table");
            }else {
                NSLog(@"success to creating db table");
            }
            [db close];
        }
    }
    
    return db;
}

#pragma mark - handel db

+ (void)insert:(WYMultitaskDloader *)download {
    FMDatabase *db = [self createDB];
    
    if ([db open]) {
        NSString *filePath = [download.filePath stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""];
        
        NSString *insertSql= [NSString stringWithFormat:@"INSERT INTO DOWNLOAD (FILEID, URL, FILEPATH, MUTILINEJSON, STATE, PROGRESS) VALUES ('%@', '%@', '%@', '%@','%@', '%@')", download.fileId, download.url, filePath, download.multilineJson, @(download.state), @(download.progress)];
        
        BOOL res = [db executeUpdate:insertSql];
        if (!res) {
            NSLog(@"error when insert db table");
        }else {
            NSLog(@"success to insert db table");
        }
        [db close];
    }
}

+ (void)update:(WYMultitaskDloader *)download {
    FMDatabase *db = [self createDB];
    
    if ([db open]) {
        NSString *insertSql= [NSString stringWithFormat:@"UPDATE DOWNLOAD SET MUTILINEJSON = '%@', STATE = '%@', PROGRESS = '%@' WHERE FILEID = '%@'", download.multilineJson, @(download.state), @(download.progress), download.fileId];
        
        BOOL res = [db executeUpdate:insertSql];
        if (!res) {
            NSLog(@"error when update db table");
        }else {
            NSLog(@"success to update db table");
        }
        [db close];
    }
}

+ (NSMutableArray *)query:(NSInteger)state {
    NSMutableArray *array = [NSMutableArray array];
    
    FMDatabase *db = [self createDB];
    if ([db open]) {
        NSString *querySql;
        if (state == 2) {
            querySql = [NSString stringWithFormat:@"SELECT * FROM DOWNLOAD WHERE STATE <= '%ld'",(long)state];
        }else {
            querySql = [NSString stringWithFormat:@"SELECT * FROM DOWNLOAD WHERE STATE = '%ld'",(long)state];
        }
        FMResultSet *rs = [db executeQuery:querySql];
        
        while ([rs next]) {
            NSString *filePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(),[rs stringForColumn:@"FILEPATH"]];
            
            WYMultitaskDloader *downloader = [WYMultitaskDloader downloader];
            downloader.fileId = [rs stringForColumn:@"FILEID"];
            downloader.url = [rs stringForColumn:@"URL"];
            downloader.filePath = filePath;
            downloader.multilineJson = [rs stringForColumn:@"MUTILINEJSON"];
            downloader.progress = [rs doubleForColumn:@"PROGRESS"];
            downloader.state = (int)state;
            
            [array addObject:downloader];
        }
        [db close];
    }
    return array;
}

+ (NSString *)queryJSON:(NSString *)fileId {
    FMDatabase *db = [self createDB];
    NSString *mutiline = @"";
    if ([db open]) {
        NSString *querySql = [NSString stringWithFormat:@"SELECT * FROM DOWNLOAD WHERE FILEID = '%@'", fileId];
        
        FMResultSet *rs = [db executeQuery:querySql];
        
        while ([rs next]) {
            mutiline = [rs stringForColumn:@"MUTILINEJSON"];
        }
        [db close];
    }
    return mutiline;
}

+ (void)delete:(WYMultitaskDloader *)download {
    FMDatabase *db = [self createDB];
    
    if ([db open]) {
        NSString *insertSql= [NSString stringWithFormat:@"DELETE FROM DOWNLOAD WHERE FILEID = '%@'", download.fileId];
        
        BOOL res = [db executeUpdate:insertSql];
        if (!res) {
            NSLog(@"error when delete db table");
        }else {
            NSLog(@"success to delete db table");
        }
        [db close];
    }
}


@end
