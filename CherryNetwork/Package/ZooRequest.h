
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import "ZooBaseRequest.h"

@interface ZooRequest : ZooBaseRequest
//是否使用缓存
@property (nonatomic,assign)BOOL useCache;
//返回当前缓存的对象
@property (nonatomic, strong, readonly) id cacheData;
@property (nonatomic) BOOL ignoreCache;
@property (nonatomic, assign) NSInteger cacheTime;



- (NSInteger)cacheTimeInSeconds;
- (void)startWithoutCache;
@end
