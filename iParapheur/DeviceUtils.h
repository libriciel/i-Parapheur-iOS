
#import <Foundation/Foundation.h>

@interface DeviceUtils : NSObject


+ (BOOL)isConnectedToDemoServer;

+ (void)logError:(NSError *)error;

+ (void)logErrorMessage:(NSString *)message;

+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title;
	
+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title
	   inViewController:(UIViewController *)viewController;

+ (void)logSuccessMessage:(NSString *)message;

+ (void)logInfoMessage:(NSString *)message;

+ (void)logInfoMessage:(NSString *)message
			 withTitle:(NSString *)title;

+ (void)logWarningMessage:(NSString *)message
				withTitle:(NSString *)title;

+ (void)logWarningMessage:(NSString *)message;


@end
