
#import "ADLRestClient.h"
#import "DeviceUtils.h"


@implementation ADLRestClient


static NSNumber *PARAPHEUR_API_VERSION;
static int PARAPHEUR_API_MAX_VERSION = 4;


+ (id)sharedManager {
	static ADLRestClient *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}


-(NSNumber *)getRestApiVersion {
	return PARAPHEUR_API_VERSION;
}


-(void)setRestApiVersion:(NSNumber *)apiVersion {
	
	if ([apiVersion intValue] != PARAPHEUR_API_VERSION) {
		PARAPHEUR_API_VERSION = apiVersion;
		[self resetClient];
	}
}


- (id)init {
	[self resetClient];
	return self;
}


- (void)resetClient{
	
	_restClientApi = nil;
	
	if ([PARAPHEUR_API_VERSION intValue] == 4)
		_restClientApi = [[ADLRestClientApi4 alloc] init];
	else
		_restClientApi = [[ADLRestClientApi3 alloc] init];
}


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf{
	
	return [_restClientApi getDownloadUrl:dossierId
								   forPdf:isPdf];
}


-(void)downloadDocument:(NSString*)documentId
				  isPdf:(bool)isPdf
				 atPath:(NSURL*)filePath
				success:(void (^)(NSString *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi downloadDocument:documentId
							   isPdf:isPdf
							  atPath:filePath
							 success:^(NSString *string) {
								 success(string);
							 }
							 failure:^(NSError *error) {
								 failure(error);
							 }];
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
	
	[_restClientApi getApiLevel:^(NSNumber *versionNumber) {
		success(versionNumber);
		
		if ([versionNumber integerValue] > PARAPHEUR_API_MAX_VERSION)
			[DeviceUtils logWarningMessage:@"Veuillez mettre à jour votre application."
								 withTitle:@"La version du i-Parapheur associé à ce compte est trop récente pour cette application."];
	}
						failure:^(NSError *error) {
							failure(error);
						}];
}


- (void)getBureaux:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	[_restClientApi getBureaux:^(NSArray *bureaux) { success(bureaux); }
					   failure:^(NSError *error) { failure(error); }];
}


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
			filter:(NSString*)filterJson
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	[_restClientApi getDossiers:[self fixBureauId:bureau]
						   page:page
						   size:size
						 filter:(NSString*)filterJson
						success:^(NSArray *dossiers) { success(dossiers); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getDossier:(NSString*)bureauId
		  dossier:(NSString*)dossierId
		  success:(void (^)(ADLResponseDossier *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi getDossier:[self fixBureauId:bureauId]
					   dossier:dossierId
					   success:^(ADLResponseDossier *dossier) { success(dossier); }
					   failure:^(NSError *error) { failure(error); }];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi getCircuit:dossier
					   success:^(ADLResponseCircuit *circuits) { success(circuits); }
					   failure:^(NSError *error) { failure(error); }];
}


-(void)getAnnotations:(NSString*)dossier
			 document:(NSString *)document
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi getAnnotations:dossier
						  document:document
						   success:^(NSArray *annotations) { success(annotations); }
						   failure:^(NSError *error) { failure(error); }];
}


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
		  andDocument:(NSString *)document
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi actionAddAnnotation:annotation
							 forDossier:dossier
							andDocument:document
								success:^(NSArray *annotations) { success(annotations); }
								failure:^(NSError *error) { failure(error); }];
}


-(void)updateAnnotation:(NSDictionary*)annotation
				forPage:(int)page
			 forDossier:(NSString *)dossier
			andDocument:(NSString *)document
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi actionUpdateAnnotation:annotation
								   forPage:page
								forDossier:dossier
							   andDocument:document
								   success:^(NSArray *annotations) { success(annotations); }
								   failure:^(NSError *error) { failure(error); }];
}


-(void)removeAnnotation:(NSDictionary*)annotation
			 forDossier:(NSString *)dossier
			andDocument:(NSString *)document
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi actionRemoveAnnotation:annotation
								forDossier:dossier
							   andDocument:document
								   success:^(NSArray *annotations) { success(annotations); }
								   failure:^(NSError *error) { failure(error); }];
}

-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(ADLResponseSignInfo *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi getSignInfoForDossier:dossierId
								andBureau:[self fixBureauId:bureauId]
								  success:^(ADLResponseSignInfo *signInfo) { success(signInfo); }
								  failure:^(NSError *error) { failure(error); }];
}


-(void)actionViserForDossier:(NSString *)dossierId
				   forBureau:(NSString *)bureauId
		withPublicAnnotation:(NSString *)publicAnnotation
	   withPrivateAnnotation:(NSString *)privateAnnotation
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi actionViserForDossier:dossierId
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
	
	[_restClientApi actionSignerForDossier:dossierId
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
	
	[_restClientApi actionRejeterForDossier:dossierId
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
