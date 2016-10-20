/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */

#import "DeviceUtils.h"
#import "StringUtils.h"
#import <TSMessages/TSMessage.h>


@implementation DeviceUtils


+ (BOOL)isConnectedToDemoAccount {

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

	NSString *url = [preferences objectForKey:@"settings_server_url"];
	NSString *login = [preferences objectForKey:@"settings_login"];
	BOOL isDemoServer = (url == nil) || [url isEqualToString:@""] || [url isEqualToString:@"parapheur.demonstrations.adullact.org"];
	BOOL isDemoAccount = (login == nil) || [login isEqualToString:@"parapheur.demonstrations.adullact.org"];

	return (isDemoServer && isDemoAccount);
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


/**
 * Here's the trick : VFR on Android rasterizes its PDF at 72dpi.
 * Ghostscript on the server rasterize at 150dpi, and takes that as a root scale.
 * Every Annotation has a pixel-coordinates based on that 150dpi, on the server.
 * We need to translate it from 150 to 72dpi, by default.
 * <p/>
 * Not by default : The server-dpi is an open parameter, in the alfresco-global.properties file...
 * So we can't hardcode the old "150 dpi", we have to let an open parameter too, to allow any density coordinates.
 * <p/>
 * Maybe some day, we'll want some crazy 300dpi on tablets, that's why we don't want to hardcode the new "72 dpi" one.
 */
+ (CGRect)translateDpiRect:(CGRect)rect
                    oldDpi:(int)oldDpi
                    newDpi:(int)newDpi {

	return CGRectMake(rect.origin.x * newDpi / oldDpi,
			rect.origin.y * newDpi / oldDpi,
			rect.size.width * newDpi / oldDpi,
			rect.size.height * newDpi / oldDpi);
}

@end
