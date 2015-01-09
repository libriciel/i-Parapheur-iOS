//
//  ADLRestClientApi3.h
//  iParapheur
//
//  Created by Adrien Bricchi on 09/01/2015.
//
//

#import <Foundation/Foundation.h>

@interface ADLRestClientApi3 : NSObject

- (id)init;


/**
 @param success A block object to be executed when the object request operation finishes successfully.
 @param failure A block object to be executed as an error callback.
 */
- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure;


/**
 @param success A block object to be executed when the object request operation finishes successfully.
 @param failure A block object to be executed as an error callback.
 */
- (void)getBureaux:(void (^)(NSArray *bureaux))success
           failure:(void (^)(NSError *error))failure;


@end
