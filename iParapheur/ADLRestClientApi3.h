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


- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure;


- (void)getBureaux:(void (^)(NSArray *bureaux))success
           failure:(void (^)(NSError *error))failure;


@end
