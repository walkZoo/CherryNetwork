
//
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import "ZooBaseRequest.h"
#import "ZooNetWorkAgent.h"
@implementation ZooBaseRequest
-(instancetype)init {
    self=[super init];
    if (self) {
        self.requestMethod=ZooRequestMethodPOST;
        self.requestSerializerType = ZooRequestSerializerTypeJSON;
        self.responseSerializerType =ZooResponseSerializerTypeJSON;
        self.constructionBodyBlock = nil;
    }
    return self;
}


-(BOOL)useCookies{
    return NO;
}

-(id)requestParameters{
    
    return @{};
}

-(NSTimeInterval )requestTimeoutInterval{
    
    return 10;
}

-(NSString *)baseUrl{
    
    return @"";
}

-(NSString *)requestUrl{
    
    return @"";
}

/// append self to request queue
- (void)start{
    [self requestWillStartTag];
    [[ZooNetWorkAgent shareInstance] addRequest:self];
}


-(void)requestWillStartTag{
    if (self.requestStartBlock) {
        self.requestStartBlock(self);
    }
    if ([self.delegate respondsToSelector:@selector(requestWillStart:)]) {
        [self.delegate requestWillStart:self];
    }
    [self requestWillStart];
    
}
/// remove self from request queue
- (void)stop{
    self.delegate=nil;
    [[ZooNetWorkAgent shareInstance] cancelRequest:self];
}

/// block回调
- (void)startWithRequestSuccessBlock:(void(^)(ZooBaseRequest *request))success failureBlock:(void(^)(ZooBaseRequest *request))failure{
    self.requestStartBlock = success;
    self.requestFailureBlock = failure;
    [self start];
}

/// 请求成功的回调
- (void)requestCompleteFilter{
    
    
}

/// 请求失败的回调
- (void)requestFailedFilter{
    
    
}
- (void)requestWillStart {
    
    
}

@end
