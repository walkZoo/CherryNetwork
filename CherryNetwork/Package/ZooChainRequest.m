
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import "ZooChainRequest.h"

@interface ZooChainRequest()<CheeryRequestDelegate>

@property (strong, nonatomic) NSMutableArray *requestArray;
@property (strong, nonatomic) NSMutableArray *requestCallbackArray;
@property (assign, nonatomic) NSUInteger nextRequestIndex;
@property (strong, nonatomic) ChainCallBack emptyCallback;
@end

@implementation ZooChainRequest

-(id)init{
    
    self=[super init];
    if (self) {
        _nextRequestIndex=0;
        _requestArray=[NSMutableArray array];
        _requestCallbackArray=[NSMutableArray array];
        _emptyCallback=^(ZooChainRequest *chainRequest,ZooBaseRequest *baseRequest){
        };

    }

    return  self;

}

/// start chain request
- (void)start{
    if (_nextRequestIndex > 0) {
        
        NSLog(@"Error! Chain request has already started.");
        return;
    }
    
    if ([_requestArray count] > 0) {
   
        [self startNextRequest];
  
    } else {
     
        NSLog(@"Error! Chain request array is empty.");
    }
    
}

/// stop chain request
- (void)stop{
    [self clearRequest];
}


-(BOOL)startNextRequest{
    
    if (_nextRequestIndex < [_requestArray count]) {
        ZooBaseRequest *request=_requestArray[_nextRequestIndex];
        _nextRequestIndex++;
        request.Cherrydelegate=self;
        [request start];
        return YES;
    }
    
        return NO;
}

- (void)addRequest:(ZooBaseRequest *)request callback:(ChainCallBack)callback{
    
    [_requestArray addObject:request];
    if (callback != nil) {
        [_requestCallbackArray addObject:callback];
    } else {
        [_requestCallbackArray addObject:_emptyCallback];
    }
}
- (NSArray *)requestArray {
    return _requestArray;
}


#pragma mark - Network Request Delegate
- (void)requestFinished:(ZooBaseRequest *)request{
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    ChainCallBack callback = _requestCallbackArray[currentRequestIndex];
    callback(self, request);
    if (![self startNextRequest]) {

        if ([_delegate respondsToSelector:@selector(chainRequestFinished:)]) {
            [_delegate chainRequestFinished:self];        }

    }
    
}
- (void)requestFailed:(ZooBaseRequest *)request{

    if ([_delegate respondsToSelector:@selector(chainRequestFailed:failBaseRequest:)]) {
     
        [_delegate chainRequestFailed:self failBaseRequest:request];

    }

}
- (void)clearRequest{
    
    NSUInteger currentRequestIndex = _nextRequestIndex - 1;
    if (currentRequestIndex < [_requestArray count]) {
        ZooBaseRequest *request = _requestArray[currentRequestIndex];
        [request stop];
    }
    [_requestArray removeAllObjects];
    [_requestCallbackArray removeAllObjects];
    
}



@end
