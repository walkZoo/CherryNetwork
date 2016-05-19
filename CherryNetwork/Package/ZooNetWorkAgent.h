
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZooBaseRequest.h"
#import <AFNetworking/AFNetworking.h>

typedef NS_ENUM(NSInteger, ZooRequestReachabilityStatus) {
    ZooRequestReachabilityStatusUnknow = 0,
    ZooRequestReachabilityStatusNotReachable,
    ZooRequestReachabilityStatusViaWWAN,
    ZooRequestReachabilityStatusViaWiFi
};

@interface ZooNetWorkAgent : NSObject


+ (ZooNetWorkAgent *)shareInstance;

@property (nonatomic, assign, readonly) ZooRequestReachabilityStatus reachabilityStatus;
- (void)addRequest:(ZooBaseRequest *)request;
- (void)cancelRequest:(ZooBaseRequest *)request;
- (void)cancelAllRequests;
// start monitor network status
- (void)startNetworkStateMonitoring;

@end
