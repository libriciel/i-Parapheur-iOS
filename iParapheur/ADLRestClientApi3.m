#import "ADLRestClientApi3.h"
#import "ADLResponseGetLevel.h"
#import "ADLResponseBureau.h"
#import "ADLResponseDossiers.h"
#import "ADLResponseAnnotation.h"


@implementation ADLRestClientApi3


- (id)init {

	// Retrieve info from settings

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

	// Init

	[self initRestClientWithLogin:loginSettings
	                     password:passwordSettings
	                          url:urlSettings];

	return self;
}


- (id)initWithLogin:(NSString *)login
           password:(NSString *)password
                url:(NSString *)url {

	[self initRestClientWithLogin:login
	                     password:password
	                          url:url];

	return self;
}


- (void)initRestClientWithLogin:(NSString *)login
                       password:(NSString *)password
                            url:(NSString *)url {

	// Fix values

	if (![url hasPrefix:@"https://m."])
		url = [NSString stringWithFormat:@"https://m.%@", url];

	// Initialize AFNetworking HTTPClient

	if (_sessionManager)
		[self cancelAllOperations];

	NSURL *baseURL = [NSURL URLWithString:url];
	_sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];

	AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
	[requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[requestSerializer setAuthorizationHeaderFieldWithUsername:login password:password];

	_sessionManager.requestSerializer = requestSerializer;

	// GET needs a JSONResponseSerializer,
	// POST/PUT/DELETE needs an HTTPResponseSerializer

	AFHTTPResponseSerializer *compoundResponseSerializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[[AFJSONResponseSerializer serializer],
			[AFHTTPResponseSerializer serializer]]];
	[_sessionManager setResponseSerializer:compoundResponseSerializer];

	// Security policy, for SSL checks.
	// The .cer files (mobile server public keys) are automatically loaded from the app bundle,
	// We just have to put them in the supporting files folder

	_sessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
	_sessionManager.securityPolicy.allowInvalidCertificates = YES; // To allow non iOS recognized CA.
	_sessionManager.securityPolicy.validatesCertificateChain = NO; // Currently (iOS 7) no chain support on self-signed certificates.
	_sessionManager.securityPolicy.validatesDomainName = YES;

	// TODO : Remove NSAllowsArbitraryLoads ATS in pList file, to upgrade security from iOS8 to iOS9 level.
	//        2015/10 : iOS9 simulator (but not devices) does not properly work with self-signed certificate (wrong -9802 errors)
}


- (void)cancelAllOperations {
	[_sessionManager.operationQueue cancelAllOperations];
}


- (void)cancelAllHTTPOperationsWithPath:(NSString *)path {

	[[_sessionManager session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		[self cancelTasksInArray:dataTasks withPath:path];
		[self cancelTasksInArray:uploadTasks withPath:path];
		[self cancelTasksInArray:downloadTasks withPath:path];
	}];
}


- (void)cancelTasksInArray:(NSArray *)tasksArray
                  withPath:(NSString *)path {

	for (NSURLSessionTask *task in tasksArray) {
		NSRange range = [[[[task currentRequest] URL] absoluteString] rangeOfString:path];
		if (range.location != NSNotFound) {
			[task cancel];
		}
	}
}


- (NSString *)getDownloadUrl:(NSString *)dossierId
                      forPdf:(bool)isPdf {

	NSString* result = [NSString stringWithFormat:@"/api/node/workspace/SpacesStore/%@/content", dossierId];

	if (isPdf)
		result = [NSString stringWithFormat:@"%@;ph:visuel-pdf", result];

	return result;
}


#pragma mark - Requests


- (void)getApiLevel:(void (^)(NSNumber *))success
            failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"getApiLevel"];

	[_sessionManager GET:@"/parapheur/api/getApiLevel"
	          parameters:nil
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             // Parse check

		             NSError *error;
		             ADLResponseGetLevel *responseGetLevel = [MTLJSONAdapter modelOfClass:[ADLResponseGetLevel class]
		                                                               fromJSONDictionary:responseObject
		                                                                            error:&error];

		             if (error) {
			             failure([NSError errorWithDomain:error.domain
			                                         code:kCFURLErrorBadServerResponse
			                                     userInfo:nil]);
		             }
		             else {
			             success(responseGetLevel.level);
		             }
	             }
	             failure:^(NSURLSessionDataTask *task, NSError *error) {

		             // AFNetworking seems to throw back only BadRequest errors,
		             // There we fix them, to have proper errors (Authentication, SSL, etc)

		             NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *) task.response;

		             if (urlResponse.statusCode == 401) {
			             failure([NSError errorWithDomain:error.domain
			                                         code:kCFURLErrorUserAuthenticationRequired
			                                     userInfo:nil]);
		             }
		             else {
			             failure(error);
		             }
	             }];
}


- (void)getBureaux:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure {

	[_sessionManager GET:@"/parapheur/bureaux"
	          parameters:nil
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             // Parse result

		             NSError *error;
		             NSArray *responseBureaux = [MTLJSONAdapter modelsOfClass:[ADLResponseBureau class]
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


- (void)getDossiers:(NSString *)bureau
               page:(int)page
               size:(int)size
             filter:(NSString *)filterJson
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

	NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] init];
	[queryParams setValue:@true forKey:@"asc"];
	[queryParams setValue:bureau forKey:@"bureau"];
	[queryParams setValue:@(page) forKey:@"page"];
	[queryParams setValue:@(size) forKey:@"pageSize"];
	[queryParams setValue:@0 forKey:@"pendingFile"];
	[queryParams setValue:@(page * (size - 1)) forKey:@"skipped"];
	[queryParams setValue:@"cm:create" forKey:@"sort"];

	if (filterJson != nil)
		[queryParams setValue:filterJson forKey:@"filter"];

	//@"corbeilleName" : @"",
	//@"metas" : @"",

	[_sessionManager GET:@"/parapheur/dossiers"
	          parameters:queryParams
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             NSError *error;
		             NSArray *responseDossiers = [MTLJSONAdapter modelsOfClass:[ADLResponseDossiers class]
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


- (void)getDossier:(NSString *)bureau
           dossier:(NSString *)dossier
           success:(void (^)(ADLResponseDossier *))success
           failure:(void (^)(NSError *))failure {

	NSDictionary *queryParams = @{@"bureauCourant" : bureau};

	[_sessionManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@", dossier]
	          parameters:queryParams
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             NSError *error;
		             ADLResponseDossier *responseDossier = [MTLJSONAdapter modelOfClass:[ADLResponseDossier class]
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


- (void)getSignInfoForDossier:(NSString *)dossierId
                    andBureau:(NSString *)bureauId
                      success:(void (^)(ADLResponseSignInfo *))success
                      failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"getSignInfo"];

	NSDictionary *queryParams = @{@"bureauCourant" : bureauId};

	[_sessionManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@/getSignInfo", dossierId]
	          parameters:queryParams
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             NSError *error;
		             ADLResponseSignInfo *responseSignInfo = [MTLJSONAdapter modelOfClass:[ADLResponseSignInfo class]
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


- (void)getCircuit:(NSString *)dossier
           success:(void (^)(ADLResponseCircuit *))success
           failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"circuit"];

	[_sessionManager GET:[NSString stringWithFormat:@"/parapheur/dossiers/%@/circuit", dossier]
	          parameters:nil
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             NSError *error;
		             ADLResponseCircuit *responseCircuit = [MTLJSONAdapter modelOfClass:[ADLResponseCircuit class]
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


- (void)getAnnotations:(NSString *)dossier
              document:(NSString *)document
               success:(void (^)(NSArray *))success
               failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:[self getAnnotationsUrlForDossier:dossier
	                                                            andDocument:document]];

	[_sessionManager GET:[self getAnnotationsUrlForDossier:dossier
	                                           andDocument:document]
	          parameters:nil
	             success:^(NSURLSessionDataTask *task, id responseObject) {

		             //TODO : Proper (Mantle based) JSON parse

		             @try {
			             NSArray *responseArray = responseObject;
			             NSMutableArray *result = [[NSMutableArray alloc] init];

			             for (id element in responseArray) {
				             ADLResponseAnnotation *response = [[ADLResponseAnnotation alloc] init];
				             response.data = element;
				             [result addObject:response];
			             }

			             success(result);
		             }
		             @catch (NSException *e) {
			             failure(nil);
		             }

	             }
	             failure:^(NSURLSessionDataTask *task, NSError *error) {
		             failure(error);
	             }];
}


#pragma mark - Download


- (void)downloadDocument:(NSString *)documentId
                   isPdf:(bool)isPdf
                  atPath:(NSURL *)filePathUrl
                 success:(void (^)(NSString *))success
                 failure:(void (^)(NSError *))failure {

	// Cancel previous download

	[[_sessionManager session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		for (NSURLSessionTask *task in downloadTasks)
			[task cancel];
	}];

	// Define download request

	NSString *downloadUrlSuffix = [self getDownloadUrl:documentId
	                                            forPdf:isPdf];

	NSString *downloadUrlString = [NSString stringWithFormat:@"%@%@", _sessionManager.baseURL, downloadUrlSuffix];
	NSMutableURLRequest *request = [_sessionManager.requestSerializer requestWithMethod:@"GET"
	                                                                          URLString:downloadUrlString
	                                                                         parameters:nil
	                                                                              error:nil];

	// Start download

	NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request
	                                                                         progress:nil
	                                                                      destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		                                                                      return filePathUrl;
	                                                                      }
	                                                                completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		                                                                if (error == nil)
			                                                                success(filePath.path);
		                                                                else if (error.code != kCFURLErrorCancelled)
			                                                                failure(error);
	                                                                }];

	[downloadTask resume];
}


#pragma mark - Simple action template


typedef enum {
	ADLRequestTypePOST = 1,
	ADLRequestTypePUT = 2,
	ADLRequestTypeDELETE = 3
} ADLRequestType;


- (void)sendSimpleAction:(ADLRequestType)type
                 withUrl:(NSString *)url
                withArgs:(NSDictionary *)args
                 success:(void (^)(NSArray *))success
                 failure:(void (^)(NSError *))failure {

	if (type == ADLRequestTypePOST) {
		[_sessionManager POST:url
		           parameters:args
		              success:^(NSURLSessionDataTask *operation, id responseObject) {
			              success(nil);
		              }
		              failure:^(NSURLSessionDataTask *operation, NSError *error) {
			              failure(error);
		              }];
	}
	else if (type == ADLRequestTypePUT) {
		[_sessionManager PUT:url
		          parameters:args
		             success:^(NSURLSessionDataTask *operation, id responseObject) {
			             success(nil);
		             }
		             failure:^(NSURLSessionDataTask *operation, NSError *error) {
			             failure(error);
		             }];
	}
	else if (type == ADLRequestTypeDELETE) {
		[_sessionManager DELETE:url
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


- (NSMutableDictionary *)fixAddAnnotationDictionary:(NSDictionary *)annotation {

	NSMutableDictionary *result = [NSMutableDictionary new];

	result[@"author"] = [annotation valueForKey:@"author"];
	result[@"text"] = [annotation valueForKey:@"text"];
	result[@"type"] = [annotation valueForKey:@"type"];
	result[@"page"] = [annotation valueForKey:@"page"];
	result[@"uuid"] = [annotation valueForKey:@"uuid"];

	NSDictionary *annotationRect = [annotation valueForKey:@"rect"];
	NSDictionary *annotationRectBottomRight = [annotationRect valueForKey:@"bottomRight"];
	NSDictionary *annotationRectTopLeft = [annotationRect valueForKey:@"topLeft"];

	NSMutableDictionary *resultBottomRight = [NSMutableDictionary new];
	resultBottomRight[@"x"] = [annotationRectBottomRight valueForKey:@"x"];
	resultBottomRight[@"y"] = [annotationRectBottomRight valueForKey:@"y"];

	NSMutableDictionary *resultTopLeft = [NSMutableDictionary new];
	resultTopLeft[@"x"] = [annotationRectTopLeft valueForKey:@"x"];
	resultTopLeft[@"y"] = [annotationRectTopLeft valueForKey:@"y"];

	NSMutableDictionary *rect = [NSMutableDictionary new];
	rect[@"bottomRight"] = resultBottomRight;
	rect[@"topLeft"] = resultTopLeft;

	result[@"rect"] = rect;

	return result;
}


- (NSMutableDictionary *)fixUpdateAnnotationDictionary:(NSDictionary *)annotation
                                               forPage:(NSNumber *)page {

	NSMutableDictionary *result = [NSMutableDictionary new];

	// Fixme : send every other data form annotation

	result[@"page"] = page;
	result[@"text"] = [annotation valueForKey:@"text"];
	result[@"type"] = [annotation valueForKey:@"type"];
	result[@"uuid"] = [annotation valueForKey:@"uuid"];
	result[@"id"] = [annotation valueForKey:@"uuid"];

	NSDictionary *annotationRect = [annotation valueForKey:@"rect"];
	NSDictionary *annotationRectBottomRight = [annotationRect valueForKey:@"bottomRight"];
	NSDictionary *annotationRectTopLeft = [annotationRect valueForKey:@"topLeft"];

	NSMutableDictionary *resultBottomRight = [NSMutableDictionary new];
	resultBottomRight[@"x"] = [annotationRectBottomRight valueForKey:@"x"];
	resultBottomRight[@"y"] = [annotationRectBottomRight valueForKey:@"y"];

	NSMutableDictionary *resultTopLeft = [NSMutableDictionary new];
	resultTopLeft[@"x"] = [annotationRectTopLeft valueForKey:@"x"];
	resultTopLeft[@"y"] = [annotationRectTopLeft valueForKey:@"y"];

	NSMutableDictionary *rect = [NSMutableDictionary new];
	rect[@"bottomRight"] = resultBottomRight;
	rect[@"topLeft"] = resultTopLeft;

	result[@"rect"] = rect;

	return result;
}


- (NSString *)getAnnotationsUrlForDossier:(NSString *)dossier
                              andDocument:(NSString *)document {

	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations", dossier];
}


- (NSString *)getAnnotationUrlForDossier:(NSString *)dossier
                             andDocument:(NSString *)document
                         andAnnotationId:(NSString *)annotationId {

	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations/%@", dossier, annotationId];
}


#pragma mark - Simple actions
// TODO : MailSecretaire


- (void)actionViserForDossier:(NSString *)dossierId
                    forBureau:(NSString *)bureauId
         withPublicAnnotation:(NSString *)publicAnnotation
        withPrivateAnnotation:(NSString *)privateAnnotation
                      success:(void (^)(NSArray *))success
                      failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [NSMutableDictionary new];
	argumentDictionary[@"bureauCourant"] = bureauId;
	argumentDictionary[@"annotPriv"] = privateAnnotation;
	argumentDictionary[@"annotPub"] = publicAnnotation;

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


- (void)actionSignerForDossier:(NSString *)dossierId
                     forBureau:(NSString *)bureauId
          withPublicAnnotation:(NSString *)publicAnnotation
         withPrivateAnnotation:(NSString *)privateAnnotation
                 withSignature:(NSString *)signature
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure {

	NSMutableDictionary *argumentDictionary = [NSMutableDictionary new];
	argumentDictionary[@"bureauCourant"] = bureauId;
	argumentDictionary[@"annotPriv"] = privateAnnotation;
	argumentDictionary[@"annotPub"] = publicAnnotation;
	argumentDictionary[@"signature"] = signature;

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


- (void)actionRejeterForDossier:(NSString *)dossierId
                      forBureau:(NSString *)bureauId
           withPublicAnnotation:(NSString *)publicAnnotation
          withPrivateAnnotation:(NSString *)privateAnnotation
                        success:(void (^)(NSArray *))success
                        failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [NSMutableDictionary new];
	argumentDictionary[@"bureauCourant"] = bureauId;
	argumentDictionary[@"annotPriv"] = privateAnnotation;
	argumentDictionary[@"annotPub"] = publicAnnotation;

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


- (void)actionSwitchToPaperSignatureForDossier:(NSString *)dossierId
                                     forBureau:(NSString *)bureauId
                                       success:(void (^)(NSArray *))success
                                       failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [NSMutableDictionary new];
	argumentDictionary[@"bureauCourant"] = bureauId;

	// Send request

	[self sendSimpleAction:ADLRequestTypePOST
	               withUrl:[NSString stringWithFormat:@"/parapheur/dossiers/%@/signPapier", dossierId]
	              withArgs:argumentDictionary
	               success:^(NSArray *result) {
		               success(nil);
	               }
	               failure:^(NSError *error) {
		               failure(error);
	               }];
}


- (void)actionAddAnnotation:(NSDictionary *)annotation
                 forDossier:(NSString *)dossierId
                andDocument:(NSString *)document
                    success:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self fixAddAnnotationDictionary:annotation];

	// Send request

	[self sendSimpleAction:ADLRequestTypePOST
	               withUrl:[self getAnnotationsUrlForDossier:dossierId
	                                             andDocument:document]
	              withArgs:argumentDictionary
	               success:^(NSArray *result) {
		               success(nil);
	               }
	               failure:^(NSError *error) {
		               failure(error);
	               }];
}


- (void)actionUpdateAnnotation:(NSDictionary *)annotation
                       forPage:(int)page
                    forDossier:(NSString *)dossierId
                   andDocument:(NSString *)document
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self fixUpdateAnnotationDictionary:annotation
	                                                                      forPage:@(page)];

	// Send request

	[self sendSimpleAction:ADLRequestTypePUT
	               withUrl:[self getAnnotationUrlForDossier:dossierId
	                                            andDocument:document
	                                        andAnnotationId:annotation[@"uuid"]]
	              withArgs:argumentDictionary
	               success:^(NSArray *result) {
		               success(nil);
	               }
	               failure:^(NSError *error) {
		               failure(error);
	               }];
}


- (void)actionRemoveAnnotation:(NSDictionary *)annotation
                    forDossier:(NSString *)dossierId
                   andDocument:(NSString *)document
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self fixUpdateAnnotationDictionary:annotation
	                                                                      forPage:@0];

	// Send request

	[self sendSimpleAction:ADLRequestTypeDELETE
	               withUrl:[self getAnnotationUrlForDossier:dossierId
	                                            andDocument:document
	                                        andAnnotationId:annotation[@"uuid"]]
	              withArgs:argumentDictionary
	               success:^(NSArray *result) {
		               success(nil);
	               }
	               failure:^(NSError *error) {
		               failure(error);
	               }];
}


@end
