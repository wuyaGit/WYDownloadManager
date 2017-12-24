# WYDownloadManager
多线程、分割片段下载数据，充分利用移动端多核处理器，加速下载速率。

# 1、导入说明
（1）支持pod导入 （需要导入FMDB第三方库）
    
    pod 'FMDB'
    pod 'WYProgressView'
    
 （2）直接下载源码，导入项目
 ![示例3](https://github.com/wuyaGit/WYDownloadManager/blob/master/ScreenShot/E447AFF6-5738-44D8-994D-12A379A7272B.png)
 
  # 2、使用说明
  
    //第一步：设置数据库保存路径
    [WYDownloadManager sharedInstance].dbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];

    //第二步：获取全部下载任务（不是必须的，需要时调用）
    [[WYDownloadManager sharedInstance] loadAll];
    
    //第三步：开始下载（组合获取progressHandler，successHandler）
    [[WYDownloadManager sharedInstance] start:@{@"fileId":task.fileId,
                                                    @"url":task.url,
                                                    @"filePath":task.filePath,
                                                    @"multilineJson":task.multilineJson}
                                    progressBlock:task.progressHandler
                                     successBlock:task.successHandler
                                        completed:nil];
        
      //第四步：获取下载进度（单独获取progressHandler）
      [[WYDownloadManager sharedInstance] multiProgressBlock:task.fileId block:^(double progress) {
          NSLog(@"下载进度%f", progress);
          
          //获取当前下载网速
          NSString *speed = [[WYDownloadManager sharedInstance] getNetworkSpeedFrom:task.fileId];
      }];
        
      //第五步：下载成功回调（单独获取successHandler）
      [[WYDownloadManager sharedInstance] multiSuccessBlock:task.fileId block:^(NSString *fileId, NSString *path, NSError *error) {
        if (error) {
            NSLog(@"下载出错");
        }else {
            NSLog(@"下载完成，其他操作");
        }
    }];
    
# 3、示例

