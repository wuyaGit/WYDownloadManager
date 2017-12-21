//
//  ViewController.m
//  WYDownloadManagerDemo
//
//  Created by YANGGL on 2017/12/21.
//  Copyright © 2017年 YANGGL. All rights reserved.
//

#import "ViewController.h"
#import "WYDownloadManager.h"
#import "DownloadTask.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *tasks;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //第一步：设置数据库保存路径
    [WYDownloadManager sharedInstance].dbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];

    //第二步：获取全部下载任务（不是必须的，需要时调用）
    [[WYDownloadManager sharedInstance] loadAll];
    
    NSArray *urls = @[@"http://mov.bn.netease.com/movie/2011/1/H/L/S6P3JEGHL.flv",
                      @"http://mov.bn.netease.com/movie/2011/1/B/Q/S6P3JF4BQ.flv",
                      @"http://mov.bn.netease.com/movie/2011/1/2/6/S6P3JG726.flv",
                      @"http://mov.bn.netease.com/movie/2011/1/R/4/S6P3JGAR4.flv",
                      @"http://mov.bn.netease.com/movie/2011/1/4/I/S6P3JIP4I.flv"];
    //添加数据
    for (NSInteger i = 0; i < 5; i++) {
        DownloadTask *task = [[DownloadTask alloc] init];
        task.name = [NSString stringWithFormat:@"下载 %@", @(i+1)];
        task.url = urls[i];

        task.fileId = [task.url lastPathComponent];
        task.filePath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Library/Caches/%@", [task.url lastPathComponent]]];
        task.multilineJson = [[WYDownloadManager sharedInstance] getMultilineJSONFrom:task.fileId];
        task.progress = [[WYDownloadManager sharedInstance] getMultiProgressFrom:task.fileId];
        
        [self.tasks addObject:task];
    }
    [self.view addSubview:self.tableView];
    
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 80.f;
    }
    
    return _tableView;
}

- (NSMutableArray *)tasks {
    if (!_tasks) {
        _tasks = [[NSMutableArray alloc] init];
    }
    return _tasks;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    if (![cell viewWithTag:2017]) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 12, tableView.frame.size.width - 50, 20)];
        [progressView setTag:2017];
        [cell.contentView addSubview:progressView];
    }
    DownloadTask *task = self.tasks[indexPath.row];
    
    cell.textLabel.text = task.name;
    cell.detailTextLabel.text = task.url;
    ((UIProgressView *)[cell viewWithTag:2017]).progress = task.progress;
    
    [self reloadProgressBlock:cell downloadTask:task];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadTask *task = self.tasks[indexPath.row];

    if ([[WYDownloadManager sharedInstance] getDownloadStateForm:task.fileId] == WYDownloadStateDown) {
        [[WYDownloadManager sharedInstance] pause:task.fileId completed:nil];
    }else if ([[WYDownloadManager sharedInstance] getDownloadStateForm:task.fileId] == WYDownloadStateNo ||
              [[WYDownloadManager sharedInstance] getDownloadStateForm:task.fileId] == WYDownloadStatePause) {
        //第三步：开始下载
//        [[WYDownloadManager sharedInstance] start:@{@"fileId":task.fileId,
//                                                      @"url":task.url,
//                                                      @"filePath":task.filePath,
//                                                      @"multilineJson":task.multilineJson} completed:nil];
        
        //第三步：开始下载（组合获取progressHandler，successHandler）
        [[WYDownloadManager sharedInstance] start:@{@"fileId":task.fileId,
                                                    @"url":task.url,
                                                    @"filePath":task.filePath,
                                                    @"multilineJson":task.multilineJson}
                                    progressBlock:task.progressHandler
                                     successBlock:task.successHandler
                                        completed:nil];
        
        //第四步：获取下载进度（单独获取progressHandler）
        [[WYDownloadManager sharedInstance] multiProgressBlock:task.fileId block:task.progressHandler];
        
        //第五步：下载成功回调（单独获取successHandler）
        [[WYDownloadManager sharedInstance] multiSuccessBlock:task.fileId block:task.successHandler];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)reloadProgressBlock:(UITableViewCell *)cell downloadTask:(__weak DownloadTask *)task {
    task.progressHandler = ^(double progress) {
        ((UIProgressView *)[cell viewWithTag:2017]).progress = progress;
        cell.textLabel.text = [NSString stringWithFormat:@"%@  %@", task.name, [[WYDownloadManager sharedInstance] getNetworkSpeedFrom:task.fileId]];
    };
    
    task.successHandler = ^(NSString *fileId, NSString *path, NSError *error) {
        if (error) {
            NSLog(@"下载出错");
        }else {
            NSLog(@"下载完成");
        }
    };
}

@end
