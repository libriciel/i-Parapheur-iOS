#import "DeviceUtils.h"
#import "StringUtils.h"
#import <TSMessage.h>


@implementation DeviceUtils


+ (BOOL)isConnectedToDemoServer {
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *url_preference = [preferences objectForKey:@"settings_server_url"];
	BOOL isDemoServer = (url_preference == nil) || [url_preference isEqualToString:@""] || [url_preference isEqualToString:@"parapheur.demonstrations.adullact.org"];
	
	return isDemoServer;
}


+ (void)logError:(NSError *)error {
	[self logErrorMessage:[StringUtils getErrorMessage:error]];
}


+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title
	   inViewController:(UIViewController *)viewController {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationInViewController:viewController
											  title:message
										   subtitle:nil
											   type:TSMessageNotificationTypeError];
	});
}


+ (void)logErrorMessage:(NSString *)message {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:message
										type:TSMessageNotificationTypeError];
	});
}


+ (void)logErrorMessage:(NSString *)message
			  withTitle:(NSString *)title {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:title
									subtitle:message
										type:TSMessageNotificationTypeError];
	});
}


+ (void)logSuccessMessage:(NSString *)message {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:message
										type:TSMessageNotificationTypeSuccess];
	});
}


+ (void)logSuccessMessage:(NSString *)message
                withTitle:(NSString *)title {

	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:title
		                            subtitle:message
		                                type:TSMessageNotificationTypeSuccess];
	});
}


+ (void)logInfoMessage:(NSString *)message {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:message
										type:TSMessageNotificationTypeMessage];
	});
}


+ (void)logInfoMessage:(NSString *)message
			 withTitle:(NSString *)title {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:title
									subtitle:message
										type:TSMessageNotificationTypeMessage];
	});
}


+ (void)logWarningMessage:(NSString *)message
				withTitle:(NSString *)title {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:title
									subtitle:message
										type:TSMessageNotificationTypeWarning];
	});
}


+ (void)logWarningMessage:(NSString *)message {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//call back to main queue to update user interface
		[TSMessage showNotificationWithTitle:message
										type:TSMessageNotificationTypeWarning];
	});
}


@end
