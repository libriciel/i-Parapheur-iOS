
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


- (void)getBureaux:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure {
    
    [_restClientApi3 getBureaux:^(NSArray *bureaux) { success(bureaux); }
                        failure:^(NSError *error) { failure(error); }];
}


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	NSString *prefixToRemove = @"workspace://SpacesStore/";
	if ([bureau hasPrefix:prefixToRemove])
		bureau = [bureau substringFromIndex:prefixToRemove.length];
	
	[_restClientApi3 getDossiers:bureau
							page:page
							size:size
						 success:^(NSArray *dossiers) { success(dossiers); }
						 failure:^(NSError *error) { failure(error); }];
}


@end
