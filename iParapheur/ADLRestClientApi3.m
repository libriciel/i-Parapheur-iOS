#import "ADLRestClientApi3.h"

#import "AFHTTPClient.h"
#import <RestKit.h>
#import "ADLResponseGetLevel.h"
#import "ADLResponseBureau.h"
#import "ADLResponseDossiers.h"
#import "ADLResponseDossier.h"
#import "ADLResponseCircuit.h"
#import "ADLResponseAnnotation.h"

@implementation ADLRestClientApi3


-(id)init {
	
	// Retrieve infos from settings
	NSString *urlSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"url_preference"];
	NSString *url = [NSString stringWithFormat:@"https://m.%@", urlSettings];
	NSString *loginSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"login_preference"];
	NSString *passwordSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"password_preference"];
	
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
	
	return self;
}


-(NSString *)getDownloadUrl:(NSString *)dossierId {
	
	// Retrieve infos from settings
	NSString *urlSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"url_preference"];
	NSString *url = [NSString stringWithFormat:@"https://m.%@", urlSettings];
	
	return [NSString stringWithFormat:@"/api/node/workspace/SpacesStore/%@/content;ph:visuel-pdf", dossierId];
}


#pragma mark getApiLevel


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
	
	[[RKObjectManager sharedManager] getObjectsAtPath:@"/parapheur/api/getApiLevel"
										   parameters:nil
											  success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
												  ADLResponseGetLevel *levelResponse = (ADLResponseGetLevel *) mappingResult.array[0];
												  success(levelResponse.level);
											  }
											  failure:^(RKObjectRequestOperation *operation, NSError *error) {
												  failure(error);
											  }];
}


#pragma mark getBureaux


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
												  NSLog(@"getBureaux size of %lu", (sizeof mappingResult.array));
												  success(mappingResult.array);
											  }
											  failure:^(RKObjectRequestOperation *operation, NSError *error) {
												  failure(error);
											  }];
}


#pragma mark getDossiers


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


#pragma mark getDossier


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


#pragma mark getCircuit


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


#pragma mark getAnnotations


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


@end
