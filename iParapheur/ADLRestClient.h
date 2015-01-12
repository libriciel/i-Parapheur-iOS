
#import <Foundation/Foundation.h>
#import "ADLRestClientApi3.h"

@interface ADLRestClient : NSObject

@property (nonatomic, strong) ADLRestClientApi3* restClientApi3;


- (id)init;


-(void)getApiLevel:(void (^)(NSNumber *))success
		   failure:(void (^)(NSError *))failure;


-(void)getBureaux:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure;


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure;


@end
