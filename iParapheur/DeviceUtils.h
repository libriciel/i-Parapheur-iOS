
#import <Foundation/Foundation.h>

@interface DeviceUtils : NSObject


+ (BOOL)isConnectedToInternet;

+ (void)logErrorMessage:(NSError *)message;

@end
