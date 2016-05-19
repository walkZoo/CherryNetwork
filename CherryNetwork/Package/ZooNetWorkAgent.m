
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import "ZooNetWorkAgent.h"
#import <AFNetworking/AFURLSessionManager.h>
#import  <AFNetworking/AFNetworkActivityIndicatorManager.h>
#define DZ_HTTP_COOKIE_KEY @"DZHTTPCookieKey"
@implementation ZooNetWorkAgent{
    AFHTTPSessionManager *sessionManager;
    NSMutableDictionary *requests;
}

+ (ZooNetWorkAgent *)shareInstance{
    
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    
    return sharedInstance;
}

- (instancetype)init{
    
    self=[super init];
    if (self) {
        sessionManager=[AFHTTPSessionManager manager];
        requests=[NSMutableDictionary dictionary];
        sessionManager.operationQueue.maxConcurrentOperationCount=5;
    }
    return self;
}

- (NSString *)configRequestURL:(ZooBaseRequest *)request {
    
    NSString * baseUrl = [request baseUrl];
    NSString * requestUrl = [request requestUrl];
    
    if ([baseUrl hasSuffix:@"/"]) {
        return [NSString stringWithFormat:@"%@%@", baseUrl,requestUrl];
    } else {
        return [NSString stringWithFormat:@"%@/%@", baseUrl,requestUrl];
    }
}



#pragma mark - cookies
- (void)saveCookies {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    if (cookies.count > 0) {
        NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:cookies];
        
        [[NSUserDefaults standardUserDefaults] setObject:cookieData forKey:DZ_HTTP_COOKIE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)loadCookies {
    id cookieData = [[NSUserDefaults standardUserDefaults] objectForKey:DZ_HTTP_COOKIE_KEY];
    if (!cookieData) {
        return;
    }
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
    if ([cookies isKindOfClass:[NSArray class]] && cookies.count > 0) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in cookies) {
            [cookieStorage setCookie:cookie];
        }
    }
}
#pragma mark - 请求结束处理
- (void)requestDidFinishTag:(ZooBaseRequest *)request {
    
    if (request.error) {
        if (request.requestFailureBlock) {
            request.requestFailureBlock(request);
        }
        
        if ([request.delegate respondsToSelector:@selector(requestDidFailure:)]) {
            [request.delegate requestDidFailure:request];
        }
        
        [request requestFailedFilter];
    } else {
        if (request.requestSuccessBlock) {
            request.requestSuccessBlock(request);
        }
        
        if ([request.delegate respondsToSelector:@selector(requestDidSuccess:)]) {
            [request.delegate requestDidSuccess:request];
        }
        
        [request requestCompleteFilter];
    }
    //    [request clearRequestBlock];
    
}

- (void)handleReponseResult:(NSURLSessionDataTask *)task response:(id)responseObject error:(NSError *)error{
    NSString *key = [self taskHashKey:task];
    ZooBaseRequest *request = requests[key];
    request.responseObject = responseObject;
    request.error = error;
    
    // 使用cookie时需要保存cookie
    if (request.useCookies) {
        [self saveCookies];
    }
    
    // 发送结束tag
    [self requestDidFinishTag:request];
    
    // 请求成功后移除此次请求
    [self removeRequest:task];
}

- (NSString *)taskHashKey:(NSURLSessionDataTask *)task {
    return [NSString stringWithFormat:@"%lu", (unsigned long)[task hash]];
}

// 管理`request`的生命周期, 防止多线程处理同一key
- (void)addZooRequest:(ZooBaseRequest *)request {
    if (request.task) {
        NSString *key = [self taskHashKey:request.task];
        @synchronized(self) {
            [requests setValue:request forKey:key];
        }
    }
}
- (void)removeRequest:(NSURLSessionDataTask *)task {
    NSString *key = [self taskHashKey:task];
    @synchronized(self) {
        [requests removeObjectForKey:key];
    }
}
#pragma mark - Public
- (void)addRequest:(ZooBaseRequest *)request {
    // 使用cookie
    if (request.useCookies) {
        [self loadCookies];
    }
   // 处理URL
    NSString *urlCoded = [self configRequestURL:request];
    NSString *url = [urlCoded stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // 处理参数
    id params = request.requestParameters;
    if (request.requestSerializerType == ZooRequestSerializerTypeJSON) {
        if (![NSJSONSerialization isValidJSONObject:params] && params) {
            // DZDebugLog(@"error in JSON parameters：%@", params);
            return;
        }
    }
    
    // 处理序列化类型
    ZooRequestSerializerType requestSerializerType = request.requestSerializerType;
    switch (requestSerializerType) {
        case ZooRequestSerializerTypeForm:
            sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case ZooRequestSerializerTypeJSON:
            sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        default:
            break;
    }
    sessionManager.requestSerializer.timeoutInterval = request.requestTimeoutInterval;
    
    ZooResponseSerializerType responseSerializerType = request.responseSerializerType;
    switch (responseSerializerType) {
        case ZooResponseSerializerTypeJSON:
            sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case ZooResponseSerializerTypeHTTP:
            sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        default:
            break;
    }
    sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", @"text/xml", @"text/plain", @"text/json", @"text/javascript", @"image/png", @"image/jpeg", @"application/json", nil];
    
    // 处理请求
    ZooRequestMethod requestMethod = request.requestMethod;
    NSURLSessionDataTask *task = nil;
    switch (requestMethod) {
        case ZooRequestMethodGET:{
            
            
            task= [sessionManager GET:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
            
        }
            break;
            
        case ZooRequestMethodPOST:{
            if ([request constructionBodyBlock]) {
                task  = [sessionManager POST:url parameters:params constructingBodyWithBlock:[request constructionBodyBlock] success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    [self handleReponseResult:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self handleReponseResult:task response:nil error:error];
                }];
                
            } else {
                task=[sessionManager POST:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                    [self handleReponseResult:task response:responseObject error:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    [self handleReponseResult:task response:nil error:error];
                }];
                
                
            }
        }
            break;
        case ZooRequestMethodPUT:{
            task = [sessionManager PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
        }
            break;
            
        case ZooRequestMethodDELETE:{
            task = [sessionManager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self handleReponseResult:task response:responseObject error:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self handleReponseResult:task response:nil error:error];
            }];
        }
            break;
        default:
            break;
    }
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    request.task = task;
    [self addZooRequest:request];
}

- (void)cancelRequest:(ZooBaseRequest *)request {
    [request.task cancel];
    [self removeRequest:request.task];
}

- (void)cancelAllRequests {
    
    for (NSString *key in requests) {
        ZooBaseRequest *request = requests[key];
        [self cancelRequest:request];
    }
}


// start monitor network status
- (void)startNetworkStateMonitoring{
    
    [sessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _reachabilityStatus = ZooRequestReachabilityStatusUnknow;
                break;
            case AFNetworkReachabilityStatusNotReachable:
                _reachabilityStatus = ZooRequestReachabilityStatusNotReachable;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _reachabilityStatus = ZooRequestReachabilityStatusViaWWAN;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _reachabilityStatus = ZooRequestReachabilityStatusViaWiFi;
                break;
            default:
                break;
        }
    }];
    [sessionManager.reachabilityManager startMonitoring];
}


@end
