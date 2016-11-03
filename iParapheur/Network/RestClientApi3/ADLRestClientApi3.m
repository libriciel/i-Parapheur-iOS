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
#import <Mantle/MTLJSONAdapter.h>
#import "ADLRestClientApi3.h"
#import "iParapheur-Swift.h"
#import "DeviceUtils.h"


@implementation ADLRestClientApi3


- (id)init {

	// Fetch selected Account Id

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *selectedAccountId = [preferences objectForKey:[Account PreferencesKeySelectedAccount]];

	if (selectedAccountId.length == 0)
		selectedAccountId = [Account DemoId];

	// Fetch Account model values

	NSString *urlSettings = nil;
	NSString *loginSettings = nil;
	NSString *passwordSettings = nil;

	NSArray *accountList = [ModelsDataController fetchAccounts];

	for (Account *account in accountList) {
		if ([selectedAccountId isEqualToString:account.unwrappedId]) {
			urlSettings = account.unwrappedUrl;
			loginSettings = account.unwrappedLogin;
			passwordSettings =  account.unwrappedPassword;
		}
	}

	// Demo values

	if ((urlSettings == nil) || (urlSettings.length == 0)) {
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

	if (_swiftManager)
		[self cancelAllOperations];

	_swiftManager = [[RestClientApiV3 alloc] initWithBaseUrl:url
	                                                   login:login
	                                                password:password];
}


- (void)cancelAllOperations {

	[_swiftManager.manager.operationQueue cancelAllOperations];
}


- (void)cancelAllHTTPOperationsWithPath:(NSString *)path {

	[_swiftManager.manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
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

	[_swiftManager getApiVersion:^(NSNumber *level) {
		 success(level);
	 }
	                     onError:^(NSError *error) {
		                     failure([NSError errorWithDomain:_swiftManager.manager.baseURL.absoluteString
		                                                 code:kCFURLErrorUserAuthenticationRequired
		                                             userInfo:nil]);
	                     }];
}


- (void)getBureaux:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure {

	[self cancelAllHTTPOperationsWithPath:@"bureaux"];

	[_swiftManager getBureaux:^(NSArray *response) {
		 success(response);
	 }
	                  onError:^(NSError *error) {
		                  failure([NSError errorWithDomain:_swiftManager.manager.baseURL.absoluteString
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
		               success(response);
	                }
					   onError:^(NSError *error) {
						   failure(error);
	                   }];
}


- (void)getTypology:(NSString *)bureauId
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

	[_swiftManager getTypology:bureauId
	                onResponse:^(NSArray *response) {
		                success(response);
	                }
	                   onError:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getDossier:(NSString *)bureau
           dossier:(NSString *)dossier
           success:(void (^)(Dossier *))success
           failure:(void (^)(NSError *))failure {

	[_swiftManager getDossier:dossier
	                   bureau:bureau
	               onResponse:^(Dossier *response) {
		               success(response);
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
	                   onResponse:^(id annotations) {
		                   success(annotations);
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

	[_swiftManager.manager.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
		for (NSURLSessionTask *task in downloadTasks)
			[task cancel];
	}];

	// Define download request

	NSString *downloadUrlSuffix = [self getDownloadUrl:documentId
	                                            forPdf:isPdf];

	NSString *downloadUrlString = [NSString stringWithFormat:@"%@%@",
	                                                         _swiftManager.manager.baseURL,
	                                                         downloadUrlSuffix];
	NSMutableURLRequest *request = [_swiftManager.manager.requestSerializer requestWithMethod:@"GET"
	                                                                                URLString:downloadUrlString
	                                                                               parameters:nil
	                                                                                    error:nil];

	// Start download

	NSURLSessionDownloadTask *downloadTask = [_swiftManager.manager downloadTaskWithRequest:request
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


- (NSMutableDictionary *)fixAddAnnotationDictionary:(Annotation *)annotation {

	NSMutableDictionary *result = [NSMutableDictionary new];

//	result[@"author"] = annotation.unwrappedAuthor;
	result[@"text"] = annotation.unwrappedText;
	result[@"type"] = annotation.unwrappedType;
	result[@"page"] = annotation.unwrappedPage;
//	result[@"uuid"] = annotation.unwrappedId;

	CGRect rect = [DeviceUtils translateDpiRect:annotation.unwrappedRect.CGRectValue
	                                     oldDpi:72
	                                     newDpi:150];
	NSDictionary *annotationRectTopLeft = @{
			@"x" : @(rect.origin.x),
			@"y" : @(rect.origin.y)
	};
	NSDictionary *annotationRectBottomRight = @{
			@"x" : @(rect.origin.x + rect.size.width),
			@"y" : @(rect.origin.y + rect.size.height)
	};

	result[@"rect"] = @{
			@"topLeft" : annotationRectTopLeft,
			@"bottomRight" : annotationRectBottomRight
	};

	return result;
}


- (NSMutableDictionary *)createAnnotationDictionary:(Annotation *)annotation {

	NSMutableDictionary *result = [NSMutableDictionary new];

	// Fixme : send every other data form annotation

	result[@"page"] = annotation.unwrappedPage;
	result[@"text"] = annotation.unwrappedText;
	result[@"type"] = annotation.unwrappedType;
	result[@"uuid"] = annotation.unwrappedId;
	result[@"id"] = annotation.unwrappedId;

	CGRect rectData = [DeviceUtils translateDpiRect:annotation.unwrappedRect.CGRectValue
	                                         oldDpi:72
	                                         newDpi:150];

	NSMutableDictionary *resultTopLeft = [NSMutableDictionary new];
	resultTopLeft[@"x"] = @(rectData.origin.x);
	resultTopLeft[@"y"] = @(rectData.origin.y);

	NSMutableDictionary *resultBottomRight = [NSMutableDictionary new];
	resultBottomRight[@"x"] = @(rectData.origin.x + rectData.size.width);
	resultBottomRight[@"y"] = @(rectData.origin.y + rectData.size.height);

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


- (void)actionAddAnnotation:(Annotation *)annotation
                 forDossier:(NSString *)dossierId
                    success:(void (^)(NSArray *))success
                    failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self fixAddAnnotationDictionary:annotation];

	// Send request

	[_swiftManager sendSimpleAction:@(1)
	                            url:[self getAnnotationsUrlForDossier:dossierId
	                                                      andDocument:annotation.unwrappedDocumentId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
		                        failure(error);
	                        }];
}


- (void)actionUpdateAnnotation:(Annotation *)annotation
                    forDossier:(NSString *)dossierId
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self createAnnotationDictionary:annotation];

	// Send request

	[_swiftManager sendSimpleAction:@(2)
	                            url:[self getAnnotationUrlForDossier:dossierId
	                                                     andDocument:annotation.unwrappedDocumentId
	                                                 andAnnotationId:annotation.unwrappedId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
		                        failure(error);
	                        }];
}


- (void)actionRemoveAnnotation:(Annotation *)annotation
                    forDossier:(NSString *)dossierId
                       success:(void (^)(NSArray *))success
                       failure:(void (^)(NSError *))failure {

	// Create arguments dictionary

	NSMutableDictionary *argumentDictionary = [self createAnnotationDictionary:annotation];

	// Send request

	[_swiftManager sendSimpleAction:@(3)
	                            url:[self getAnnotationUrlForDossier:dossierId
	                                                     andDocument:annotation.unwrappedDocumentId
	                                                 andAnnotationId:annotation.unwrappedId]
	                           args:argumentDictionary
	                     onResponse:^(id result) {
		                     success(nil);
	                     }
	                        onError:^(NSError *error) {
		                        failure(error);
	                        }];
}


@end
