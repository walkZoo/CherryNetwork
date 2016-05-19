
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import "ZooRequest.h"
#import "ZooNetworkPrivate.h"

@interface ZooRequest()

@property (nonatomic, strong) id cacheData;

@end

@implementation ZooRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.useCache = YES;
        
    }
    return self;
}
-(NSInteger)cacheTimeInSeconds{
    if(self.cacheTime>0){
        
        return self.cacheTime;
    }else{
        
        return  -1;
        
    }
}



- (void)startWithoutCache{
    
    [super start];
    
}


- (void)start {
    if (self.useCache) {
        [super start];
        return;
    }
    
    // check cache time
    if ([self cacheTimeInSeconds] < 0) {
        [super start];
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[self cacheFilePath]]) {
        [super start];
        return;
    }
    
    NSTimeInterval fileTimeInterval = [self cacheFileTimeInterval:[self cacheFilePath]];
    NSTimeInterval cacheTimeInterval = [self cacheTimeInSeconds];
    if (cacheTimeInterval <= 0 || cacheTimeInterval < fileTimeInterval) {
        [super start];
        return;
    }
    [self requestDidFinishTag];
}

- (NSInteger)cacheFileTimeInterval:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
    if (error) {
        return -1;
    }
    NSTimeInterval timeInterval = -[[attributes fileModificationDate] timeIntervalSinceNow];
    return timeInterval;
}

-(void)requestDidFinishTag {
    self.responseObject = self.cacheData;
    if (self.error) {
        if (self.requestFailureBlock) {
            self.requestFailureBlock(self);
        }
        
        if ([self.delegate respondsToSelector:@selector(requestDidFailure:)]) {
            [self.delegate requestDidFailure:self];
        }
    } else {
        if (self.requestSuccessBlock) {
            self.requestSuccessBlock(self);
        }
        
        if ([self.delegate respondsToSelector:@selector(requestDidSuccess:)]) {
            [self.delegate requestDidSuccess:self];
        }
    }
    //        [self clearRequestBlock];
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [[NSNotificationCenter defaultCenter] postNotificationName:DZRequestDidFinishNotification object:self];
    //        });
    
}

-(id)cacheData{
    if (_cacheData) {
        return _cacheData;
    } else {
        NSString *path = [self cacheFilePath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path isDirectory:nil] == YES) {
            _cacheData = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        }
        return _cacheData;
    }
    
}



- (NSString *)cacheFilePath {
    NSString *cacheFileName = [self cacheFileName];
    NSString *path = [self cacheBasePath];
    path = [path stringByAppendingPathComponent:cacheFileName];
    return path;
}

- (NSString *)cacheFileName {
    
    ZooRequestMethod method = [self requestMethod];
    NSString *baseURL = [self baseUrl];
    NSString *requestURL = [self requestUrl];
    
    NSString *fileName = [NSString stringWithFormat:@"method-%ld_host-%@_url:%@", method, baseURL, requestURL];
    return [ZooNetworkPrivate md5StringFromString:fileName];
}


- (NSString *)cacheBasePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [cachePath stringByAppendingPathComponent:@"LazyRequestCache"];
    
    [self checkDirectory:path];
    return path;
}

- (void)checkDirectory:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        [self createBaseDirectoryAtPath:path];
    } else {
        if (!isDir) {
            NSError *error = nil;
            [fileManager removeItemAtPath:path error:&error];
            [self createBaseDirectoryAtPath:path];
        }
    }
}

- (void)createBaseDirectoryAtPath:(NSString *)path {
    __autoreleasing NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        
    } else {
        [self addDoNotBackupAttribute:path];
    }
}

-(void)addDoNotBackupAttribute:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        // DZDebugLog(@"error in set back up attribute: %@", error.localizedDescription);
    }
}

- (void)saveData:(id)responseObject {
    if (responseObject) {
        [NSKeyedArchiver archiveRootObject:responseObject toFile:[self cacheFilePath]];
    }
}

- (void)requestCompleteSuccess {
    [super requestCompleteFilter];
    [self saveData:self.responseObject];
}

@end
