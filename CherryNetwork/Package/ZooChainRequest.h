
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZooBaseRequest.h"


@class ZooChainRequest;
@protocol ZooChainRequestDelegate <NSObject>

@optional
-(void)chainRequestFinished:(ZooChainRequest *)chainRequest;

-(void)chainRequestFailed:(ZooChainRequest *)chainRequest failBaseRequest:(ZooBaseRequest *)request;
@end

typedef void (^ChainCallBack)(ZooChainRequest *chainRequest,ZooBaseRequest *request);

@interface ZooChainRequest : NSObject

@property (nonatomic,weak)id <ZooChainRequestDelegate>delegate;
@property (nonatomic, strong) NSMutableArray *requestAccessories;

/// start chain request
- (void)start;

/// stop chain request
- (void)stop;

- (void)addRequest:(ZooBaseRequest *)request callback:(ChainCallBack)callback;

- (NSArray *)requestArray;



@end
