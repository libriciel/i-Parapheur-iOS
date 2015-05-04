#import "DeviceUtils.h"
#import "StringUtils.h"
#import <TSMessage.h>
#import <SystemConfiguration/SystemConfiguration.h>


@implementation DeviceUtils


//+ (BOOL)isConnectedToInternet {
//	Reachability *reachability = [Reachability reachabilityForInternetConnection];
//	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
//	return networkStatus != NotReachable;
//}


+ (void)logError:(NSError *)error {
	[self logErrorMessage:[StringUtils getErrorMessage:error]];
}


+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title
	   inViewController:(UIViewController *)viewController {

	[TSMessage showNotificationInViewController:viewController
										  title:message
									   subtitle:nil
										   type:TSMessageNotificationTypeError];
}


+ (void)logErrorMessage:(NSString *)message {
	
	[TSMessage showNotificationWithTitle:message
									type:TSMessageNotificationTypeError];
}


+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title {
	
	[TSMessage showNotificationWithTitle:title
								subtitle:message
									type:TSMessageNotificationTypeError];
}


+ (void)logSuccessMessage:(NSString *)message {
	
	[TSMessage showNotificationWithTitle:message
									type:TSMessageNotificationTypeSuccess];
}


+ (void)logInfoMessage:(NSString *)message {
	
	[TSMessage showNotificationWithTitle:message
									type:TSMessageNotificationTypeMessage];
}


+ (void)logWarningMessage:(NSString *)message {
	
	[TSMessage showNotificationWithTitle:message
									type:TSMessageNotificationTypeWarning];
}


@end
