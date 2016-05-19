

//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>


/**
 *  HTTP request method
 */
typedef NS_ENUM(NSInteger, ZooRequestMethod) {
    
    ZooRequestMethodGET = 0,
    ZooRequestMethodPOST,
    ZooRequestMethodPUT,
    ZooRequestMethodDELETE
};
/**
 *  request serializer type
 */
typedef NS_ENUM(NSInteger, ZooRequestSerializerType) {
    
    ZooRequestSerializerTypeForm = 0,
    
    ZooRequestSerializerTypeJSON
};
/**
 *  response serializer type
 */
typedef NS_ENUM(NSInteger,ZooResponseSerializerType) {
    
    ZooResponseSerializerTypeHTTP= 0,
    
    ZooResponseSerializerTypeJSON
};


@class ZooBaseRequest;
typedef void(^ZooRequestCompletionBlock) (__kindof ZooBaseRequest *request);
@protocol ZooRequestDelegate <NSObject>
@optional
- (void)requestWillStart:(ZooBaseRequest *)request;
- (void)requestDidSuccess:(ZooBaseRequest *)request;
- (void)requestDidFailure:(ZooBaseRequest *)request;
@end

@protocol CheeryRequestDelegate <NSObject>

- (void)requestFinished:(ZooBaseRequest *)request;
- (void)requestFailed:(ZooBaseRequest *)request;
- (void)clearRequest;

@end


@interface ZooBaseRequest : NSObject
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic,copy)ZooRequestCompletionBlock requestStartBlock;
@property (nonatomic,copy)ZooRequestCompletionBlock requestSuccessBlock;
@property (nonatomic,copy)ZooRequestCompletionBlock requestFailureBlock;
@property (nonatomic,copy)void (^uploadProgress)(NSProgress *progress);
@property (nonatomic,strong)id responseObject;
@property (nonatomic,strong)NSError *error;

//delegate
@property (nonatomic,weak)id <ZooRequestDelegate> delegate;

@property (nonatomic,weak)id <CheeryRequestDelegate> Cherrydelegate;
//-----------------------------------------------------

/**
 *  custom properties
 *
 */
@property (nonatomic, assign) ZooRequestMethod requestMethod;
@property (nonatomic, assign) ZooRequestSerializerType requestSerializerType;
@property (nonatomic, assign) ZooResponseSerializerType responseSerializerType;
@property (nonatomic, copy) void (^constructionBodyBlock)(id<AFMultipartFormData>formData);


-(BOOL) useCookies;
/// 请求的连接超时时间
-(NSTimeInterval) requestTimeoutInterval;
- (id)requestParameters;
/// 请求的URL
- (NSString *)requestUrl;
/// 请求的BaseURL
- (NSString *)baseUrl;

/// append self to request queue
- (void)start;

/// remove self from request queue
- (void)stop;

/// block回调
- (void)startWithRequestSuccessBlock:(void(^)(ZooBaseRequest *request))success failureBlock:(void(^)(ZooBaseRequest *request))failure;

/// 请求成功的回调
- (void)requestCompleteFilter;

/// 请求失败的回调
- (void)requestFailedFilter;




@end
