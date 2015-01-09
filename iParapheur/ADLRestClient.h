//
//  ADLRestClient.h
//  iParapheur
//
//  Created by Adrien Bricchi on 09/01/2015.
//
//

#import <Foundation/Foundation.h>
#import "ADLRestClientApi3.h"

@interface ADLRestClient : NSObject

@property (nonatomic, strong) ADLRestClientApi3* restClientApi3;


- (id)init;

-(void)getApiLevel:(void (^)(NSNumber *))success failure:(void (^)(NSError *))failure;

-(void)getBureaux:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure;

@end
