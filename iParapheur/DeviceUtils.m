#import "DeviceUtils.h"
#import "Reachability.h"
#import "AJNotificationView.h"
#import "StringUtils.h"
#import <SystemConfiguration/SystemConfiguration.h>


@implementation DeviceUtils


+ (BOOL)isConnectedToInternet {
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
	return networkStatus != NotReachable;
}


+ (void)logErrorMessage:(NSError *)error {
	
	UIViewController *rootController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
	[AJNotificationView showNoticeInView:[rootController view]
									type:AJNotificationTypeRed
								   title:[StringUtils getErrorMessage:error]
						 linedBackground:AJLinedBackgroundTypeStatic
							   hideAfter:2.5f];
}


@end
