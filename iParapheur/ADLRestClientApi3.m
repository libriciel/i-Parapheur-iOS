#import "ADLRestClientApi3.h"

#import "AFHTTPClient.h"
#import <RestKit.h>
#import "ADLResponseGetLevel.h"
#import "ADLResponseBureau.h"
#import "ADLResponseDossiers.h"
#import "ADLResponseDossier.h"
#import "ADLResponseCircuit.h"
#import "ADLResponseAnnotation.h"
#import "ADLResponseSignInfo.h"
#import "Reachability.h"

@implementation ADLRestClientApi3


-(id)init {
	
	// Retrieve infos from settings
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
	NSString *urlSettings = [preferences objectForKey:@"settings_server_url"];
	NSString *url = [NSString stringWithFormat:@"https://m.%@", urlSettings];
	NSString *loginSettings = [preferences objectForKey:@"settings_login"];
	NSString *passwordSettings = [preferences objectForKey:@"settings_password"];
	
	// Initialize AFNetworking HTTPClient
	NSURL *baseURL = [NSURL URLWithString:url];
	AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
	client.allowsInvalidSSLCertificate = YES;
	[client setAuthorizationHeaderWithUsername:loginSettings
									  password:passwordSettings];
	
	// Initialize RestKit

	RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
	
	[self addApiLevelMappingRules:objectManager];
	[self addApiBureauxMappingRules:objectManager];
	[self addApiDossiersMappingRules:objectManager];
	[self addApiDossierMappingRules:objectManager];
	[self addApiCircuitMappingRules:objectManager];
	[self addApiAnnotationsMappingRules:objectManager];
	[self addSignInfoMappingRules:objectManager];

	// Update singleton
	
	[RKObjectManager setSharedManager:objectManager];
	
	return self;
}


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf {
	
	NSString* result = [NSString stringWithFormat:@"/api/node/workspace/SpacesStore/%@/content", dossierId];
	
	if (isPdf)
		result = [NSString stringWithFormat:@"%@;ph:visuel-pdf", result];
	
	return result;
}


#pragma mark - getApiLevel


-(void)addApiLevelMappingRules:(RKObjectManager *)objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseGetLevel class]];
	[mapping addAttributeMappingsFromDictionary:@{@"level": @"level"}];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/api/getApiLevel"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getApiLevel:(void (^)(NSNumber *))success
		   failure:(void (^)(NSError *))failure {
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *urlSettings = [preferences objectForKey:@"settings_server_url"];
	
	[[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/api/getApiLevel"
										   parameters:nil
											  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
												  ADLResponseGetLevel *levelResponse = (ADLResponseGetLevel *) mappingResult.array[0];
												  success(levelResponse.level);
											  }
											  failure:^(RKObjectRequestOperation *operation, NSError *error) {

												  Reachability *reach = [Reachability reachabilityWithHostname:urlSettings];
												  
												  if ([reach isReachable]) {
													  // Legacy compatibility
													  success([NSNumber numberWithInt:2]);
												  }
												  else {
													  
													  [reach setReachableBlock:^(Reachability *reachblock) {
														  // keep in mind this is called on a background thread
														  // and if you are updating the UI it needs to happen
														  // on the main thread, like this:
														  dispatch_async(dispatch_get_main_queue(), ^{ success([NSNumber numberWithInt:2]); });
													  }];
													  
													  [reach setUnreachableBlock:^(Reachability*reach) {
														  // keep in mind this is called on a background thread
														  // and if you are updating the UI it needs to happen
														  // on the main thread, like this:
														  dispatch_async(dispatch_get_main_queue(), ^{ failure(error); });
													  }];
												  }
												  
												  [reach startNotifier];
											  }];
}


#pragma mark - getBureaux


-(void)addApiBureauxMappingRules:(RKObjectManager *)objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseBureau class]];
	[mapping addAttributeMappingsFromDictionary:@{@"level":@"level",
												  @"hasSecretaire":@"hasSecretaire",
												  @"collectivite":@"collectivite",
												  @"description":@"desc",
												  @"en-preparation":@"enPreparation",
												  @"nodeRef":@"nodeRef",
												  @"shortName":@"shortName",
												  @"en-retard":@"enRetard",
												  @"image":@"image",
												  @"show_a_venir":@"showAVenir",
												  @"habilitation":@"habilitation",
												  @"a-archiver":@"aArchiver",
												  @"a-traiter":@"aTraiter",
												  @"id":@"identifier",
												  @"isSecretaire":@"isSecretaire",
												  @"name":@"name",
												  @"retournes":@"retournes",
												  @"dossiers-delegues":@"dossierDelegues"}];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/bureaux"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getBureaux:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	[[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/bureaux"
										   parameters:nil
											  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
												  //ADLResponseBureau *testBureau = (ADLResponseBureau *) mappingResult.array[0];
												  NSLog(@"getBureaux size of %d", (mappingResult.array.count));
												  success(mappingResult.array);
											  }
											  failure:^(RKObjectRequestOperation *operation, NSError *error) {
												  failure(error);
											  }];
}


#pragma mark - getDossiers


-(void)addApiDossiersMappingRules:(RKObjectManager *)objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseDossiers class]];
	[mapping addAttributeMappingsFromDictionary:@{@"total":@"total",
												  @"protocol":@"protocol",
												  @"actionDemandee":@"actionDemandee",
												  @"isSent":@"isSent",
												  @"type":@"type",
												  @"bureauName":@"bureauName",
												  @"creator":@"creator",
												  @"id":@"identifier",
												  @"title":@"title",
												  @"pendingFile":@"pendingFile",
												  @"banetteName":@"banetteName",
												  @"dateLimite":@"dateLimite",
												  @"skipped":@"skipped",
												  @"sousType":@"sousType",
												  @"isSignPapier":@"isSignPapier",
												  @"isXemEnabled":@"isXemEnabled",
												  @"hasRead":@"hasRead",
												  @"readingMandatory":@"readingMandatory",
												  @"documentPrincipal":@"documentPrincipal",
												  @"locked":@"locked",
												  @"actions":@"actions",
												  @"isRead":@"isRead",
												  @"dateEmission":@"dateEmission",
												  @"includeAnnexes":@"includeAnnexes"}];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/dossiers"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	NSDictionary *queryParams = @{@"asc" : @true,
								  @"bureau" : bureau,
								  //@"corbeilleName" : @"",
								  //@"filter" : @"",
								  //@"metas" : @"",
								  @"page" : [NSNumber numberWithInt:page],
								  @"pageSize" : [NSNumber numberWithInt:size],
								  @"pendingFile" : [NSNumber numberWithInt:0],
								  @"skipped" : [NSNumber numberWithInt:0],
								  @"sort" : @"cm:create"};
	
	[[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/dossiers"
										   parameters:queryParams
											  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
												  success(mappingResult.array);
											  }
											  failure:^(RKObjectRequestOperation *operation, NSError *error) {
												  failure(error);
											  }];
}


#pragma mark - getDossier


-(void)addApiDossierMappingRules:(RKObjectManager *)objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseDossier class]];
	[mapping addAttributeMappingsFromDictionary:@{@"title":@"title",
												  @"nomTdT":@"nomTdT",
												  @"includeAnnexes":@"includeAnnexes",
												  @"locked":@"locked",
												  @"readingMandatory":@"readingMandatory",
												  @"dateEmission":@"dateEmission",
												  @"visibility":@"visibility",
												  @"isRead":@"isRead",
												  @"actionDemandee":@"actionDemandee",
												  @"status":@"status",
												  @"documents":@"documents",
												  @"identifier":@"id",
												  @"isSignPapier":@"isSignPapier",
												  @"dateLimite":@"dateLimite",
												  @"hasRead":@"hasRead",
												  @"isXemEnabled":@"isXemEnabled",
												  @"actions":@"actions",
												  @"banetteName":@"banetteName",
												  @"type":@"type",
												  @"canAdd":@"canAdd",
												  @"protocole":@"protocole",
												  @"metadatas":@"metadatas",
												  @"xPathSignature":@"xPathSignature",
												  @"sousType":@"sousType",
												  @"bureauName":@"bureauName",
												  @"isSent":@"isSent"}];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/dossiers/:identifier"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	if (![[RKObjectManager sharedManager].router.routeSet routeForName:@"dossier_route"]) {
		[[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithName:@"dossier_route"
																			 pathPattern:@"/parapheur/dossiers/:identifier"
																				  method:RKRequestMethodGET]];
	}
	
	ADLResponseDossier *responseDossier = [ADLResponseDossier alloc];
	responseDossier.identifier = dossier;
	NSDictionary *queryParams = @{@"bureauCourant" : bureau};
	
	[[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"dossier_route"
															object:responseDossier
														parameters:queryParams
														   success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
															   success(mappingResult.array);
														   }
														   failure:^(RKObjectRequestOperation *operation, NSError *error) {
															   failure(error);
														   }];
}


#pragma mark - getSignInfo


-(void)addSignInfoMappingRules:(RKObjectManager *)objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseSignInfo class]];
	[mapping addAttributeMappingsFromDictionary:@{@"signatureInformations":@"signatureInformations"}];
	
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/dossiers/:identifier/getSignInfo"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	if (![[RKObjectManager sharedManager].router.routeSet routeForName:@"get_sign_info_route"]) {
		[[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithName:@"get_sign_info_route"
																			 pathPattern:@"/parapheur/dossiers/:identifier/getSignInfo"
																				  method:RKRequestMethodGET]];
	}

	ADLResponseDossier *responseDossier = [ADLResponseDossier alloc];
	responseDossier.identifier = dossierId;
	NSDictionary *queryParams = @{@"bureauCourant" : bureauId};
	
	[[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"get_sign_info_route"
															object:responseDossier
														parameters:queryParams
														   success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
															   success(mappingResult.array);
														   }
														   failure:^(RKObjectRequestOperation *operation, NSError *error) {
															   failure(error);
														   }];
}


#pragma mark - getCircuit


-(void)addApiCircuitMappingRules:(RKObjectManager *) objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseCircuit class]];
	[mapping addAttributeMappingsFromDictionary:@{@"etapes":@"etapes",
												  @"annotPriv":@"annotPriv",
												  @"isDigitalSignatureMandatory":@"isDigitalSignatureMandatory",
												  @"hasSelectionScript":@"hasSelectionScript",
												  @"sigFormat":@"sigFormat"}];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/dossiers/:identifier/circuit"
																						   keyPath:@"circuit"
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure {
	
	if (![[RKObjectManager sharedManager].router.routeSet routeForName:@"circuit_route"]) {
		[[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithName:@"circuit_route"
																			 pathPattern:@"/parapheur/dossiers/:identifier/circuit"
																				  method:RKRequestMethodGET]];
	}
	
	ADLResponseDossier *responseDossier = [ADLResponseDossier alloc];
	responseDossier.identifier = dossier;
	
	[[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"circuit_route"
															object:responseDossier
														parameters:nil
														   success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
															   success(mappingResult.array);
														   }
														   failure:^(RKObjectRequestOperation *operation, NSError *error) {
															   failure(error);
														   }];
}


#pragma mark - getAnnotations


-(void)addApiAnnotationsMappingRules:(RKObjectManager *) objectManager {
	
	RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[ADLResponseAnnotation class]];
	mapping.assignsNilForMissingRelationships = YES;
	[mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil
																	  toKeyPath:@"data"]];
	
	RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
																							method:RKRequestMethodGET
																					   pathPattern:@"/parapheur/dossiers/:identifier/annotations"
																						   keyPath:nil
																					   statusCodes:[NSIndexSet indexSetWithIndex:200]];
	
	[objectManager addResponseDescriptor:responseDescriptor];
}


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	if (![[RKObjectManager sharedManager].router.routeSet routeForName:@"annotations_route"]) {
		[[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithName:@"annotations_route"
																			 pathPattern:@"/parapheur/dossiers/:identifier/annotations"
																				  method:RKRequestMethodGET]];
	}
	
	ADLResponseDossier *responseDossier = [ADLResponseDossier alloc];
	responseDossier.identifier = dossier;
	
	[[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"annotations_route"
															object:responseDossier
														parameters:nil
														   success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
															   success(mappingResult.array);
														   }
														   failure:^(RKObjectRequestOperation *operation, NSError *error) {
															   failure(error);
														   }];
}


#pragma mark - Simple action template


-(void)requestSimpleAction:(NSString *)actionName
				forRequest:(RKRequestMethod)requestMethod
			forRouteObject:(NSObject *)routeObject
				forPattern:(NSString *)pathPattern
				  withArgs:(NSDictionary *)args
				   success:(void (^)(NSArray *))success
				   failure:(void (^)(NSError *))failure {

	// Define Restkit URL Route, if not exists
	
	NSString* routeName = [NSString stringWithFormat:@"%@_route", actionName];
	
	if (![[RKObjectManager sharedManager].router.routeSet routeForName:routeName]) {
		[[RKObjectManager sharedManager].router.routeSet addRoute:[RKRoute routeWithName:routeName
																			 pathPattern:pathPattern
																				  method:requestMethod]];
	}
	
	// Create request
	
	NSMutableURLRequest *request = [[RKObjectManager sharedManager] requestWithPathForRouteNamed:routeName
																						  object:routeObject
																					  parameters:nil];
	
	// Add params to custom request
	
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:args
													   options:NSJSONWritingPrettyPrinted
														 error:nil];
	
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[request setHTTPBody:jsonData];
	
	// Send request
	
	RKObjectRequestOperation* operation = [[RKObjectManager sharedManager] objectRequestOperationWithRequest:(NSURLRequest *)request
																									 success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
																										 success(operation.responseDescriptors);
																									 }
																									 failure:^(RKObjectRequestOperation *operation, NSError *error) {
																										 if (operation.HTTPRequestOperation.response.statusCode == 200)
																											 success(operation.responseDescriptors);
																										 else
																											 failure(error);
																									 }];
	
	[[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation];
}


#pragma mark - Private Methods


-(ADLResponseDossier *)getRouteDossierFromId:(NSString *)dossierId {
	ADLResponseDossier *responseDossier = [ADLResponseDossier alloc];
	responseDossier.identifier = dossierId;
	
	return responseDossier;
}


-(ADLResponseAnnotation *)getRouteAnnotationFromDossierId:(NSString *)dossierId
										  andAnnotationId:(NSString *)annotationId {
	
	ADLResponseAnnotation *responseAnnotation = [ADLResponseAnnotation alloc];
	responseAnnotation.idDossier = dossierId;
	responseAnnotation.idAnnotation = annotationId;
	
	return responseAnnotation;
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
	
	[self requestSimpleAction:@"visa"
				   forRequest:RKRequestMethodPOST
			   forRouteObject:[self getRouteDossierFromId:dossierId]
				   forPattern:@"/parapheur/dossiers/:identifier/visa"
					 withArgs:argumentDictionary
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
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary= [NSMutableDictionary new];
	[argumentDictionary setObject:bureauId forKey:@"bureauCourant"];
	[argumentDictionary setObject:privateAnnotation forKey:@"annotPriv"];
	[argumentDictionary setObject:publicAnnotation forKey:@"annotPub"];
	[argumentDictionary setObject:signature forKey:@"signature"];
	
	// Send request
	
	[self requestSimpleAction:@"signature"
				   forRequest:RKRequestMethodPOST
			   forRouteObject:[self getRouteDossierFromId:dossierId]
				   forPattern:@"/parapheur/dossiers/:identifier/signature"
					 withArgs:argumentDictionary
					  success:^(NSArray *result) {
						  success(result);
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
	
	[self requestSimpleAction:@"rejet"
				   forRequest:RKRequestMethodPOST
			   forRouteObject:[self getRouteDossierFromId:dossierId]
				   forPattern:@"/parapheur/dossiers/:identifier/rejet"
					 withArgs:argumentDictionary
					  success:^(NSArray *result) {
						  success(result);
					  }
					  failure:^(NSError *error) {
						  failure(error);
					  }];
};


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


-(void)actionAddAnnotation:(NSDictionary*)annotation
				forDossier:(NSString *)dossierId
				   success:(void (^)(NSArray *))success
				   failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary = [self fixAddAnnotationDictionary:annotation];
	
	// Send request
	
	[self requestSimpleAction:@"annotation"
				   forRequest:RKRequestMethodPOST
			   forRouteObject:[self getRouteDossierFromId:dossierId]
				   forPattern:@"/parapheur/dossiers/:identifier/annotations"
					 withArgs:argumentDictionary
					  success:^(NSArray *result) {
						  success(result);
					  }
					  failure:^(NSError *error) {
						  failure(error);
					  }];
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


-(void)actionUpdateAnnotation:(NSDictionary*)annotation
					  forPage:(int)page
				   forDossier:(NSString *)dossierId
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure {
	
	// Create arguments dictionnary
	
	NSMutableDictionary *argumentDictionary = [self fixUpdateAnnotationDictionary:annotation
																		  forPage:[NSNumber numberWithInt:page]];
	
	// Send request
	
	[self requestSimpleAction:@"annotation_action_update"
				   forRequest:RKRequestMethodPUT
			   forRouteObject:[self getRouteAnnotationFromDossierId:dossierId andAnnotationId:[annotation objectForKey:@"uuid"]]
				   forPattern:@"/parapheur/dossiers/:idDossier/annotations/:idAnnotation"
					 withArgs:argumentDictionary
					  success:^(NSArray *result) {
						  success(result);
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
	
	[self requestSimpleAction:@"annotation_action_delete"
				   forRequest:RKRequestMethodDELETE
			   forRouteObject:[self getRouteAnnotationFromDossierId:dossierId andAnnotationId:[annotation objectForKey:@"uuid"]]
				   forPattern:@"/parapheur/dossiers/:idDossier/annotations/:idAnnotation"
					 withArgs:argumentDictionary
					  success:^(NSArray *result) {
						  success(result);
					  }
					  failure:^(NSError *error) {
						  failure(error);
					  }];
}


@end
