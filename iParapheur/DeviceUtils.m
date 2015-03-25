#import "DeviceUtils.h"
#import "Reachability.h"
#import "DeviceUtils.h"
#import "StringUtils.h"
#import <ALAlertBanner/ALAlertBanner.h>
#import <SystemConfiguration/SystemConfiguration.h>


@implementation DeviceUtils


+ (BOOL)isConnectedToInternet {
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	NetworkStatus networkStatus = [reachability currentReachabilityStatus];
	return networkStatus != NotReachable;
}


+ (void)logError:(NSError *)error {
	[self logErrorMessage:[StringUtils getErrorMessage:error]];
}


+ (void)logErrorMessage:(NSString *)message {

	UIView *mainView = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	[self logErrorMessage:message
				   inView:mainView];
}


+ (void)logErrorMessage:(NSString *)message
				 inView:(UIView *)view {
	
	// Create banner
	
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:view
														style:ALAlertBannerStyleFailure
													 position:ALAlertBannerPositionTop
														title:@"Erreur"
													 subtitle:message];
	banner.secondsToShow = 2.0f;
	
	// Simple test, to avoid full error screen (this should never happen in a normal case)
	
	NSArray *existingBanners = [ALAlertBanner alertBannersInView:(UIView *)view];
	if (existingBanners.count >= 5)
		return;

	// Show

	[banner show];
}


+ (void)logInfoMessage:(NSString *)message {
	
	UIView *mainView = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController].view;
	ALAlertBanner *banner = [ALAlertBanner alertBannerForView:mainView
														style:ALAlertBannerStyleSuccess
													 position:ALAlertBannerPositionTop
														title:@"Terminé"
													 subtitle:message];
	[banner show];
}


@end
