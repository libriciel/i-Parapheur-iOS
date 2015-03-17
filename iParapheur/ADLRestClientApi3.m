#import "ADLRestClientApi3.h"

#import "ADLResponseGetLevel.h"
#import "ADLResponseBureau.h"
#import "ADLResponseDossiers.h"
#import "ADLResponseDossier.h"
#import "ADLResponseCircuit.h"
#import "ADLResponseAnnotation.h"
#import "NSString+Contains.h"
#import "StringUtils.h"
#import "ADLResponseSignInfo.h"
#import "Reachability.h"

@implementation ADLRestClientApi3


-(id)init {
	
	// Retrieve infos from settings
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
	NSString *urlSettings = [preferences objectForKey:@"settings_server_url"];
	NSString *loginSettings = [preferences objectForKey:@"settings_login"];
	NSString *passwordSettings = [preferences objectForKey:@"settings_password"];
	
	// Demo values
	
	if (urlSettings.length == 0) {
		urlSettings = @"parapheur.demonstrations.adullact.org";
		loginSettings = @"bma";
		passwordSettings = @"secret";
	}
	
	// Fix values
	
	if (![urlSettings hasPrefix:@"https://m."])
		urlSettings = [NSString stringWithFormat:@"https://m.%@", urlSettings];
	
	// Initialize AFNetworking HTTPClient
	
	NSURL *baseURL = [NSURL URLWithString:urlSettings];
	_getManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
	_postManager = 	[[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
	
	// GetManager init
	
	[_getManager.requestSerializer setAuthorizationHeaderFieldWithUsername:loginSettings
																  password:passwordSettings];
	
	// PostManager init
	//		Here are the reasons why we have two managers : GET needs a HTTPRequestSerializer/JSONResponseSerializer
	//		and PUT/POST/DELETE needs the opposite : JSONRequestSerializer/HTTPResponseSerializer.
	//		(We can't change them on runtime without messing with the requests in the waiting list)
	
	AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
	[requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[requestSerializer setAuthorizationHeaderFieldWithUsername:loginSettings
													  password:passwordSettings];
	
	_postManager.requestSerializer = requestSerializer;
	
	AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
	[_postManager setResponseSerializer:responseSerializer];
	
	// Security policy, for SSL checks.
	// The .cer files (mobile server public keys) are automatically loaded from the app bundle,
	// We just have to put them in the supporting files folder
	
	_getManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
	_getManager.securityPolicy.allowInvalidCertificates = YES; // To allow non iOS recognized CA.
	_getManager.securityPolicy.validatesCertificateChain = NO; // Currently (iOS 7) no chain support on self-signed certificates.
	_getManager.securityPolicy.validatesDomainName = YES;
	
	_postManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
	_postManager.securityPolicy.allowInvalidCertificates = YES; // To allow non iOS recognized CA.
	_postManager.securityPolicy.validatesCertificateChain = NO; // Currently (iOS 7) no chain support on self-signed certificates.
	_postManager.securityPolicy.validatesDomainName = YES;
	
	return self;
}


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf {
	
	NSString* result = [NSString stringWithFormat:@"/api/node/workspace/SpacesStore/%@/content", dossierId];
	
	if (isPdf)
		result = [NSString stringWithFormat:@"%@;ph:visuel-pdf", result];
	
	return result;
}


#pragma mark - Requests


-(void)getApiLevel:(void (^)(NSNumber *))success
		   failure:(void (^)(NSError *))failure {
	
	
	[_getManager GET:@"/parapheur/api/getApiLevel"
		  parameters:nil
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 // Parse check
				 
				 NSError *error;
				 ADLResponseGetLevel* responseGetLevel = [MTLJSONAdapter modelOfClass:[ADLResponseGetLevel class]
																   fromJSONDictionary:responseObject
																				error:&error];
				 
				 // Callback
				 // TODO Adrien : test API2.
				 
				 if (error)
					 success([NSNumber numberWithInt:2]);
				 else
					 success(responseGetLevel.level);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {

				 NSLog(@"Adrien getApiLevel fail : %@", error.localizedDescription);

				 // AFNetworking seems to throw back only BadRequest errors,
				 // There we fix them, to have proper errors (Authentication, SSL, etc)
				 
				 NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse*)task.response;
				 
				 if (urlResponse.statusCode == 401){
					 failure([NSError errorWithDomain:error.domain
												 code:kCFURLErrorUserAuthenticationRequired
											 userInfo:nil]);
				 }
				 else {
					 failure(error);
				 }
			 }];
}


-(void)getBureaux:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	[_getManager GET:@"/parapheur/bureaux"
		  parameters:nil
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 // Parse result
				 
				 NSError *error;
				 NSArray* responseBureaux = [MTLJSONAdapter modelsOfClass:[ADLResponseBureau class]
															fromJSONArray:responseObject
																	error:&error];
				 
				 // Callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseBureaux);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
			filter:(NSString*)filterJson
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] init];
	[queryParams setValue:@true forKey:@"asc"];
	[queryParams setValue:bureau forKey:@"bureau"];
	[queryParams setValue:[NSNumber numberWithInt:page] forKey:@"page"];
	[queryParams setValue:[NSNumber numberWithInt:size] forKey:@"pageSize"];
	[queryParams setValue:[NSNumber numberWithInt:0] forKey:@"pendingFile"];
	[queryParams setValue:[NSNumber numberWithInt:0] forKey:@"skipped"];
	[queryParams setValue:@"cm:create" forKey:@"sort"];
	
	if (filterJson != nil)
		[queryParams setValue:filterJson forKey:@"filter"];
	
	//@"corbeilleName" : @"",
	//@"metas" : @"",
	
	[_getManager GET:@"/parapheur/dossiers"
		  parameters:queryParams
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 NSError *error;
				 NSArray* responseDossiers = [MTLJSONAdapter modelsOfClass:[ADLResponseDossiers class]
															 fromJSONArray:responseObject
																	 error:&error];
				 
				 // Parse check and callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseDossiers);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(ADLResponseDossier *))success
		  failure:(void (^)(NSError *))failure {
	
	NSDictionary *queryParams = @{@"bureauCourant" : bureau};
	
	[_getManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@", dossier]
		  parameters:queryParams
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 NSError *error;
				 ADLResponseDossier* responseDossier = [MTLJSONAdapter modelOfClass:[ADLResponseDossier class]
																 fromJSONDictionary:responseObject
																			  error:&error];
				 
				 // Parse check and callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseDossier);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(ADLResponseSignInfo *))success
					 failure:(void (^)(NSError *))failure {
	
	NSDictionary *queryParams = @{@"bureauCourant" : bureauId};
	
	[_getManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@/getSignInfo", dossierId]
		  parameters:queryParams
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 NSError *error;
				 ADLResponseSignInfo* responseSignInfo = [MTLJSONAdapter modelOfClass:[ADLResponseSignInfo class]
																   fromJSONDictionary:responseObject
																				error:&error];
				 
				 // Parse check and callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseSignInfo);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure {
	
	[_getManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@/circuit", dossier]
		  parameters:nil
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 NSError *error;
				 ADLResponseCircuit* responseCircuit = [MTLJSONAdapter modelOfClass:[ADLResponseCircuit class]
														   fromJSONDictionary:responseObject[@"circuit"]
																			  error:&error];
				 
				 // Parse check and callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseCircuit);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_getManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations", dossier]
		  parameters:nil
			 success:^(NSURLSessionDataTask *task, id responseObject) {
				 
				 NSError *error;
				 NSArray* responseAnnotations = [MTLJSONAdapter modelsOfClass:[ADLResponseAnnotation class]
																fromJSONArray:responseObject
																		error:&error];
				 
				 // Parse check and callback
				 
				 if (error)
					 failure(error);
				 else
					 success(responseAnnotations);
			 }
			 failure:^(NSURLSessionDataTask *task, NSError *error) {
				 failure(error);
			 }];
}


#pragma mark - Simple action template


typedef enum {
	ADLRequestTypePOST = 1,
	ADLRequestTypePUT = 2,
	ADLRequestTypeDELETE = 3
} ADLRequestType;


-(void)sendSimpleAction:(ADLRequestType)type
				withUrl:(NSString *)url
			   withArgs:(NSDictionary *)args
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	if (type == ADLRequestTypePOST) {
		[_postManager POST:url
				parameters:args
				   success:^(NSURLSessionDataTask *operation, id responseObject) {
					   success(nil);
				   }
				   failure:^(NSURLSessionDataTask *operation, NSError *error) {
					   failure(error);
				   }];
	}
	else if (type == ADLRequestTypePUT) {
		[_postManager PUT:url
				  parameters:args
					 success:^(NSURLSessionDataTask *operation, id responseObject) {
						 success(nil);
					 }
					 failure:^(NSURLSessionDataTask *operation, NSError *error) {
						 failure(error);
					 }];
	}
	else if (type == ADLRequestTypeDELETE) {
		[_postManager DELETE:url
				  parameters:args
						success:^(NSURLSessionDataTask *operation, id responseObject) {
							success(nil);
						}
						failure:^(NSURLSessionDataTask *operation, NSError *error) {
							failure(error);
						}];
	}
}


#pragma mark - Private Methods


-(NSMutableDictionary *)fixAddAnnotationDictionary:(NSDictionary *)annotation {
	
	NSMutableDictionary *result= [NSMutableDictionary new];
	
	[result setObject:[annotation valueForKey:@"author"] forKey:@"author"];
	[result setObject:[annotation valueForKey:@"text"] forKey:@"text"];
	[result setObject:[annotation valueForKey:@"type"] forKey:@"type"];
	[result setObject:[annotation valueForKey:@"page"] forKey:@"page"];
	[result setObject:[annotation valueForKey:@"uuid"] forKey:@"uuid"];
	
	NSDictionary *annotationRect = [annotation valueForKey:@"rect"];
	NSDictionary *annotationRectBottomRight = [annotationRect valueForKey:@"bottomRight"];
	NSDictionary *annotationRectTopLeft = [annotationRect valueForKey:@"topLeft"];
	
	NSMutableDictionary *resultBottomRight = [NSMutableDictionary new];
	[resultBottomRight setObject:[annotationRectBottomRight valueForKey:@"x"] forKey:@"x"];
	[resultBottomRight setObject:[annotationRectBottomRight valueForKey:@"y"] forKey:@"y"];
	
	NSMutableDictionary *resultTopLeft = [NSMutableDictionary new];
	[resultTopLeft setObject:[annotationRectTopLeft valueForKey:@"x"] forKey:@"x"];
	[resultTopLeft setObject:[annotationRectTopLeft valueForKey:@"y"] forKey:@"y"];
	
	NSMutableDictionary *rect = [NSMutableDictionary new];
	[rect setObject:resultBottomRight forKey:@"bottomRight"];
	[rect setObject:resultTopLeft forKey:@"topLeft"];
	
	[result setObject:rect forKey:@"rect"];
	
	return result;
}


-(NSMutableDictionary *)fixUpdateAnnotationDictionary:(NSDictionary *)annotation
											  forPage:(NSNumber *)page {
	
	NSMutableDictionary *result= [NSMutableDictionary new];
	
	// Fixme : send every other data form annotation
	
	[result setObject:page forKey:@"page"];
	[result setObject:[annotation valueForKey:@"text"] forKey:@"text"];
	[result setObject:[annotation valueForKey:@"type"] forKey:@"type"];
	[result setObject:[annotation valueForKey:@"uuid"] forKey:@"uuid"];
	[result setObject:[annotation valueForKey:@"uuid"] forKey:@"id"];
	
	NSDictionary *annotationRect = [annotation valueForKey:@"rect"];
	NSDictionary *annotationRectBottomRight = [annotationRect valueForKey:@"bottomRight"];
	NSDictionary *annotationRectTopLeft = [annotationRect valueForKey:@"topLeft"];
	
	NSMutableDictionary *resultBottomRight = [NSMutableDictionary new];
	[resultBottomRight setObject:[annotationRectBottomRight valueForKey:@"x"] forKey:@"x"];
	[resultBottomRight setObject:[annotationRectBottomRight valueForKey:@"y"] forKey:@"y"];
	
	NSMutableDictionary *resultTopLeft = [NSMutableDictionary new];
	[resultTopLeft setObject:[annotationRectTopLeft valueForKey:@"x"] forKey:@"x"];
	[resultTopLeft setObject:[annotationRectTopLeft valueForKey:@"y"] forKey:@"y"];
	
	NSMutableDictionary *rect = [NSMutableDictionary new];
	[rect setObject:resultBottomRight forKey:@"bottomRight"];
	[rect setObject:resultTopLeft forKey:@"topLeft"];
	
	[result setObject:rect forKey:@"rect"];
	
	return result;
}


#pragma mark - Simple actions
// TODO : MailSecretaire


-(void)actionViserForDossier:(NSString *)dossierId
				   forBureau:(NSString *)bureauId
		withPublicAnnotation:(NSString *)publicAnnotation
	   withPrivateAnnotation:(NSString *)privateAnnotation
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary= [NSMutableDictionary new];
	[argumentDictionary setObject:bureauId forKey:@"bureauCourant"];
	[argumentDictionary setObject:privateAnnotation forKey:@"annotPriv"];
	[argumentDictionary setObject:publicAnnotation forKey:@"annotPub"];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypePOST
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/visa", dossierId]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
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
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary= [NSMutableDictionary new];
	[argumentDictionary setObject:bureauId forKey:@"bureauCourant"];
	[argumentDictionary setObject:privateAnnotation forKey:@"annotPriv"];
	[argumentDictionary setObject:publicAnnotation forKey:@"annotPub"];
	[argumentDictionary setObject:signature forKey:@"signature"];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypePOST
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/signature", dossierId]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
				   }
				   failure:^(NSError *error) {
					   failure(error);
				   }];
};


-(void)actionRejeterForDossier:(NSString *)dossierId
					 forBureau:(NSString *)bureauId
		  withPublicAnnotation:(NSString *)publicAnnotation
		 withPrivateAnnotation:(NSString *)privateAnnotation
					   success:(void (^)(NSArray *))success
					   failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary= [NSMutableDictionary new];
	[argumentDictionary setObject:bureauId forKey:@"bureauCourant"];
	[argumentDictionary setObject:privateAnnotation forKey:@"annotPriv"];
	[argumentDictionary setObject:publicAnnotation forKey:@"annotPub"];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypePOST
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/rejet", dossierId]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
				   }
				   failure:^(NSError *error) {
					   failure(error);
				   }];
};


-(void)actionAddAnnotation:(NSDictionary*)annotation
				forDossier:(NSString *)dossierId
				   success:(void (^)(NSArray *))success
				   failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary = [self fixAddAnnotationDictionary:annotation];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypePOST
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations", dossierId]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
				   }
				   failure:^(NSError *error) {
					   failure(error);
				   }];
}


-(void)actionUpdateAnnotation:(NSDictionary*)annotation
					  forPage:(int)page
				   forDossier:(NSString *)dossierId
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary = [self fixUpdateAnnotationDictionary:annotation
																		  forPage:[NSNumber numberWithInt:page]];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypePUT
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations/%@", dossierId, [annotation objectForKey:@"uuid"]]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
				   }
				   failure:^(NSError *error) {
					   failure(error);
				   }];
}


-(void)actionRemoveAnnotation:(NSDictionary*)annotation
				   forDossier:(NSString *)dossierId
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary = [self fixUpdateAnnotationDictionary:annotation
																		  forPage:[NSNumber numberWithInt:0]];
	
	// Send request
	
	[self sendSimpleAction:ADLRequestTypeDELETE
				   withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations/%@", dossierId, [annotation objectForKey:@"uuid"]]
				  withArgs:argumentDictionary
				   success:^(NSArray *result) {
					   success(nil);
				   }
				   failure:^(NSError *error) {
					   failure(error);
				   }];
}


@end
