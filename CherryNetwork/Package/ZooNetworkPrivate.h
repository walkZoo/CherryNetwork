
//  Created by fanxin on 16/5/18.
//  Copyright © 2016年 fanxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZooNetworkPrivate : NSObject
FOUNDATION_EXPORT void PlutoLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
+ (NSString *)md5StringFromString:(NSString *)string;
@end
