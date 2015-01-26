
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


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf{
	return [_restClientApi3 getDownloadUrl:dossierId
									forPdf:isPdf];//
}


-(NSString *)fixBureauId:(NSString *)dossierId {
	NSString *prefixToRemove = @"workspace://SpacesStore/";

	if ([dossierId hasPrefix:prefixToRemove])
		return [dossierId substringFromIndex:prefixToRemove.length];
	else
		return dossierId;
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


-(void)getDossier:(NSString*)bureauId
		  dossier:(NSString*)dossierId
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	
	[_restClientApi3 getDossier:[self fixBureauId:bureauId]
						dossier:dossierId
						success:^(NSArray *dossiers) { success(dossiers); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getCircuit:dossier
						success:^(NSArray *circuits) { success(circuits); }
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
	
	[_restClientApi3 actionAddAnnotation:annotation
							  forDossier:dossier
								 success:^(NSArray *annotations) { success(annotations); }
								 failure:^(NSError *error) { failure(error); }];
}


-(void)updateAnnotation:(NSDictionary*)annotation
				forPage:(int)page
			 forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionUpdateAnnotation:annotation
									forPage:page
								 forDossier:dossier
									success:^(NSArray *annotations) { success(annotations); }
									failure:^(NSError *error) { failure(error); }];
}


-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getSignInfoForDossier:dossierId
								 andBureau:[self fixBureauId:bureauId]
								   success:^(NSArray *annotations) { success(annotations); }
								   failure:^(NSError *error) { failure(error); }];
}


-(void)actionViserForDossier:(NSString *)dossierId
				   forBureau:(NSString *)bureauId
		withPublicAnnotation:(NSString *)publicAnnotation
	   withPrivateAnnotation:(NSString *)privateAnnotation
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionViserForDossier:dossierId
								 forBureau:[self fixBureauId:bureauId]
					  withPublicAnnotation:publicAnnotation
					 withPrivateAnnotation:privateAnnotation
								   success:^(NSArray *result) {
									   success(result);
								   }
								   failure:^(NSError *error) {
									   failure(error);
								   }];
}


-(void)actionSignerForDossier:(NSString *)dossierId
					forBureau:(NSString *)bureauId
		 withPublicAnnotation:(NSString *)publicAnnotation
		withPrivateAnnotation:(NSString *)privateAnnotation
				withSignature:(NSString *)signature
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionSignerForDossier:dossierId
								  forBureau:[self fixBureauId:bureauId]
					   withPublicAnnotation:publicAnnotation
					  withPrivateAnnotation:privateAnnotation
							  withSignature:(NSString *)signature
									success:^(NSArray *result) {
										success(result);
									}
									failure:^(NSError *error) {
										failure(error);
									}];
}


-(void)actionRejeterForDossier:(NSString *)dossierId
					 forBureau:(NSString *)bureauId
		  withPublicAnnotation:(NSString *)publicAnnotation
		 withPrivateAnnotation:(NSString *)privateAnnotation
					   success:(void (^)(NSArray *))success
					   failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionRejeterForDossier:dossierId
								   forBureau:[self fixBureauId:bureauId]
						withPublicAnnotation:publicAnnotation
					   withPrivateAnnotation:privateAnnotation
									 success:^(NSArray *result) {
										 success(result);
									 }
									 failure:^(NSError *error) {
										 failure(error);
									 }];
}


@end
