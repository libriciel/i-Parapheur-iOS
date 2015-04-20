#import "DeviceUtils.h"
#import "StringUtils.h"
#import <ALAlertBanner/ALAlertBanner.h>
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


+ (void)logErrorMessage:(NSString *)message {

		[self logErrorMessage:nil
				withTitle:message
				   inView:nil];
}


+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title
				 inView:(UIView *)view {
	
	if (view == nil)
		view = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	
	// Create banner
	
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:view
														style:ALAlertBannerStyleFailure
													 position:ALAlertBannerPositionTop
														title:title
													 subtitle:message];
	banner.secondsToShow = 2.0f;
	
	// Simple test, to avoid full error screen (this should never happen in a normal case)
	
	NSArray *existingBanners = [ALAlertBanner alertBannersInView:(UIView *)view];
	if (existingBanners.count >= 5)
		return;

	// Show

	[banner show];
}


+ (void)logSuccessMessage:(NSString *)message {
	
	UIView *mainView = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:mainView
														style:ALAlertBannerStyleSuccess
													 position:ALAlertBannerPositionTop
														title:message
													 subtitle:nil];
	[banner show];
}


+ (void)logInfoMessage:(NSString *)message {
	
	UIView *mainView = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:mainView
														style:ALAlertBannerStyleNotify
													 position:ALAlertBannerPositionTop
														title:message
													 subtitle:nil];
	banner.secondsToShow = 5.0f;
	[banner show];
}


+ (void)logWarningMessage:(NSString *)message {
	
	UIView *mainView = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:mainView
														style:ALAlertBannerStyleWarning
													 position:ALAlertBannerPositionTop
														title:message
													 subtitle:nil];
	banner.secondsToShow = 5.0f;
	[banner show];
}


@end
