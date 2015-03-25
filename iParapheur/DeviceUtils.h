//
//  DeviceUtils.h
//  iParapheur
//
//  Created by Adrien Bricchi on 25/03/2015.
//
//

#import <Foundation/Foundation.h>

@interface DeviceUtils : NSObject


+ (BOOL)isConnectedToInternet;

+ (void)logErrorMessage:(NSError *)message;

@end
