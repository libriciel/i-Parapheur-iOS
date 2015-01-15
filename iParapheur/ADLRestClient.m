
#import "ADLRestClient.h"


@implementation ADLRestClient


static NSNumber *PARAPHEUR_API_VERSION;


+(NSNumber *)getRestApiVersion {
	return PARAPHEUR_API_VERSION;
}


- (id)init {   
    _restClientApi3 = [[ADLRestClientApi3 alloc] init];
    return self;
}


-(NSString *)getDownloadUrl:(NSString *)dossierId {
	return [_restClientApi3 getDownloadUrl:dossierId];
}

#pragma mark API calls


- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure {
    
    [_restClientApi3 getApiLevel:^(NSNumber *versionNumber) {
		PARAPHEUR_API_VERSION = versionNumber;
		success(versionNumber);
	}
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


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	NSString *prefixToRemove = @"workspace://SpacesStore/";
	if ([bureau hasPrefix:prefixToRemove])
		bureau = [bureau substringFromIndex:prefixToRemove.length];
	
	[_restClientApi3 getDossier:bureau
						dossier:dossier
						success:^(NSArray *dossiers) { success(dossiers); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getCircuit:dossier
						success:^(NSArray *dossiers) { success(dossiers); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getAnnotations:dossier
							success:^(NSArray *annotations) { success(annotations); }
							failure:^(NSError *error) { failure(error); }];
}


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 addAnnotations:annotation
						 forDossier:dossier
							success:^(NSArray *annotations) { success(annotations); }
							failure:^(NSError *error) { failure(error); }];
}


-(void)updateAnnotation:(NSDictionary*)annotation
			forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 addAnnotations:annotation
						 forDossier:dossier
							success:^(NSArray *annotations) { success(annotations); }
							failure:^(NSError *error) { failure(error); }];
}


@end
