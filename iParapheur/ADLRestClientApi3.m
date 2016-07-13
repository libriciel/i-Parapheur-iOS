/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */
#import "ADLRestClientApi3.h"
#import "ADLResponseBureau.h"
#import "ADLResponseDossiers.h"
#import "ADLResponseAnnotation.h"
#import "iParapheur-Swift.h"
#import "ADLResponseGetLevel.h"


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

//	RestClientApiV3 *restApiV3 = [[RestClientApiV3 alloc] initWithBaseUrl:@"https://m.parapheur.demonstrations.adullact.org"];
//	[restApiV3 getApiVersion];

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
		url = [NSString stringWithFormat:@"https://m.%@",
		                                 url];

	// Initialize AFNetworking HTTPClient

	if (_sessionManager)
		[self cancelAllOperations];

	NSURL *baseURL = [NSURL URLWithString:url];
	_sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];

	AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
	[requestSerializer setValue:@"application/json"
	         forHTTPHeaderField:@"Content-Type"];
	[requestSerializer setValue:@"gzip"
	         forHTTPHeaderField:@"Accept-Encoding"];
	[requestSerializer setAuthorizationHeaderFieldWithUsername:login
	                                                  password:password];

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
	// _sessionManager.securityPolicy.validatesCertificateChain = NO; // Currently (iOS 7) no chain support on self-signed certificates.
	_sessionManager.securityPolicy.validatesDomainName = YES;

	// TODO : Remove NSAllowsArbitraryLoads ATS in pList file, to upgrade security from iOS8 to iOS9 level.
	//        2015/10 : iOS9 simulator (but not devices) does not properly work with self-signed certificate (wrong -9802 errors)

	_swiftManager = [[RestClientApiV3 alloc] initWithBaseUrl:url
	                                                   login:login
	                                                password:password];
}


- (void)cancelAllOperations {

	[_sessionManager.operationQueue cancelAllOperations];
	[_swiftManager._manager.operationQueue cancelAllOperations];
}


- (void)cancelAllHTTPOperationsWithPath:(NSString *)path {

	[[_sessionManager session] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		[self cancelTasksInArray:dataTasks
		                withPath:path];
		[self cancelTasksInArray:uploadTasks
		                withPath:path];
		[self cancelTasksInArray:downloadTasks
		                withPath:path];
	}];
	[_swiftManager._manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		[self cancelTasksInArray:dataTasks
		                withPath:path];
		[self cancelTasksInArray:uploadTasks
		                withPath:path];
		[self cancelTasksInArray:downloadTasks
		                withPath:path];
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

	NSString *result = [NSString stringWithFormat:@"/api/node/workspace/SpacesStore/%@/content",
	                                              dossierId];

	if (isPdf)
		result = [NSString stringWithFormat:@"%@;ph:visuel-pdf",
		                                    result];

	return result;
}


#pragma mark - Requests


- (void)getApiLevel:(void (^)(NSNumber *))success
            failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"getApiLevel"];

	[_swiftManager getApiVersion:^(id response) {

		 // Parse check

		 NSError *error;
		 ADLResponseGetLevel *responseGetLevel = [MTLJSONAdapter modelOfClass:[ADLResponseGetLevel class]
		                                                   fromJSONDictionary:(NSDictionary *) response
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
	                     onError:^(NSError *error) {
		                     failure([NSError errorWithDomain:_swiftManager._manager.baseURL.absoluteString
		                                                 code:kCFURLErrorUserAuthenticationRequired
		                                             userInfo:nil]);
	                     }];
}


- (void)getBureaux:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"bureaux"];

	[_swiftManager getBureaux:^(id response) {

		 // Parse result

		 NSError *error;
		 NSArray *responseBureaux = [MTLJSONAdapter modelsOfClass:[ADLResponseBureau class]
		                                            fromJSONArray:response
		                                                    error:&error];

		 // Callback

		 if (error)
			 failure(error);
		 else
			 success(responseBureaux);
	 }
	                  onError:^(NSError *error) {
		                  failure([NSError errorWithDomain:_swiftManager._manager.baseURL.absoluteString
		                                              code:kCFURLErrorUserAuthenticationRequired
		                                          userInfo:nil]);
	                  }];
}


- (void)getDossiers:(NSString *)bureau
               page:(int)page
               size:(int)size
             filter:(NSString *)filterJson
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"dossiers"];

	[_swiftManager getDossiers:bureau
	                      page:@(page)
	                      size:@(size)
	                filterJson:filterJson
	                onResponse:^(NSArray *response) {

		                NSError *error;
		                NSArray *responseDossiers = [MTLJSONAdapter modelsOfClass:[ADLResponseDossiers class]
		                                                            fromJSONArray:response
		                                                                    error:&error];

		                // Parse check and callback

		                if (error)
			                failure(error);
		                else
			                success(responseDossiers);
	                }
	                   onError:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getDossier:(NSString *)bureau
           dossier:(NSString *)dossier
           success:(void (^)(ADLResponseDossier *))success
           failure:(void (^)(NSError *))failure {

	[_swiftManager getDossier:dossier
	                   bureau:bureau
	               onResponse:^(NSDictionary *response) {

		               NSError *error;
		               ADLResponseDossier *responseDossier = [MTLJSONAdapter modelOfClass:[ADLResponseDossier class]
		                                                               fromJSONDictionary:response
		                                                                            error:&error];

		               // Parse check and callback

		               if (error)
			               failure(error);
		               else
			               success(responseDossier);
	               }
	                  onError:^(NSError *error) {
		                  failure(error);
	                  }];
}


- (void)getSignInfoForDossier:(NSString *)dossierId
                    andBureau:(NSString *)bureauId
                      success:(void (^)(ADLResponseSignInfo *))success
                      failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"getSignInfo"];

	[_swiftManager getSignInfo:dossierId
	                    bureau:bureauId
	                onResponse:^(id response) {

		                NSError *error;
		                ADLResponseSignInfo *responseSignInfo = [MTLJSONAdapter modelOfClass:[ADLResponseSignInfo class]
		                                                                  fromJSONDictionary:response
		                                                                               error:&error];

		                // Parse check and callback

		                if (error)
			                failure(error);
		                else
			                success(responseSignInfo);
	                }
	                   onError:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getCircuit:(NSString *)dossier
           success:(void (^)(ADLResponseCircuit *))success
           failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"circuit"];

	[_swiftManager getCircuit:dossier
	               onResponse:^(NSDictionary *response) {

		               NSError *error;
		               ADLResponseCircuit *responseCircuit = [MTLJSONAdapter modelOfClass:[ADLResponseCircuit class]
		                                                               fromJSONDictionary:response[@"circuit"]
		                                                                            error:&error];

		               // Parse check and callback

		               if (error)
			               failure(error);
		               else
			               success(responseCircuit);
	               }
	                  onError:^(NSError *error) {
		                  failure(error);
	                  }];
}


- (void)getAnnotations:(NSString *)dossier
              document:(NSString *)document
               success:(void (^)(NSArray *))success
               failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:[self getAnnotationsUrlForDossier:dossier
	                                                            andDocument:document]];

	[_swiftManager getAnnotations:dossier
	                   onResponse:^(id responseAnnotation) {

		                   //TODO : Proper (Mantle based) JSON parse

		                   @try {
			                   NSArray *responseArray = responseAnnotation;
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
	                      onError:^(NSError *error) {
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

	[_swiftManager._manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		for (NSURLSessionTask *task in downloadTasks)
			[task cancel];
	}];

	// Define download request

	NSString *downloadUrlSuffix = [self getDownloadUrl:documentId
	                                            forPdf:isPdf];

	NSString *downloadUrlString = [NSString stringWithFormat:@"%@%@",
	                                                         _swiftManager._manager.baseURL,
	                                                         downloadUrlSuffix];
	NSMutableURLRequest *request = [_swiftManager._manager.requestSerializer requestWithMethod:@"GET"
	                                                                                 URLString:downloadUrlString
	                                                                                parameters:nil
	                                                                                     error:nil];

	// Start download

	NSURLSessionDownloadTask *downloadTask = [_swiftManager._manager downloadTaskWithRequest:request
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

	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations",
	                                  dossier];
}


- (NSString *)getAnnotationUrlForDossier:(NSString *)dossier
                             andDocument:(NSString *)document
                         andAnnotationId:(NSString *)annotationId {

	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/annotations/%@",
	                                  dossier,
	                                  annotationId];
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

	[_swiftManager sendSimpleAction:@(1)
	                            url:[NSString stringWithFormat:@"/parapheur/dossiers/%@/visa",
	                                                           dossierId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(1)
	                            url:[NSString stringWithFormat:@"/parapheur/dossiers/%@/signature",
	                                                           dossierId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(1)
	                            url:[NSString stringWithFormat:@"/parapheur/dossiers/%@/rejet",
	                                                           dossierId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(1)
	                            url:[NSString stringWithFormat:@"/parapheur/dossiers/%@/signPapier",
	                                                           dossierId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(1)
	                            url:[self getAnnotationsUrlForDossier:dossierId
	                                                      andDocument:document]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(2)
	                            url:[self getAnnotationUrlForDossier:dossierId
	                                                     andDocument:document
	                                                 andAnnotationId:annotation[@"uuid"]]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
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

	[_swiftManager sendSimpleAction:@(3)
	                            url:[self getAnnotationUrlForDossier:dossierId
	                                                     andDocument:document
	                                                 andAnnotationId:annotation[@"uuid"]]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
		                        failure(error);
	                        }];
}


@end
