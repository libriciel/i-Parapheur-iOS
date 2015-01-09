//
//  ADLRestClient.m
//  iParapheur
//
//  Created by Adrien Bricchi on 09/01/2015.
//
//

#import "ADLRestClient.h"


@implementation ADLRestClient


- (id)init {   
    _restClientApi3 = [[ADLRestClientApi3 alloc] init];
    return self;
}


#pragma mark API calls


- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure {
    
    [_restClientApi3 getApiLevel:^(NSNumber *versionNumber) { success(versionNumber); }
                         failure:^(NSError *error) { failure(error); }];
}


@end
