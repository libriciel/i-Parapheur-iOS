/*
 * Copyright 2012-2017, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
#import "ADLRestClient.h"


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


- (NSNumber *)getRestApiVersion {

	return PARAPHEUR_API_VERSION;
}


- (void)setRestApiVersion:(NSNumber *)apiVersion {

	if (apiVersion.intValue != PARAPHEUR_API_VERSION.intValue) {
		PARAPHEUR_API_VERSION = apiVersion;
		[self resetClient];
	}
}


- (id)init {

	[self resetClient];
	return self;
}


- (void)resetClient {

	_restClientApi = nil;

	if (PARAPHEUR_API_VERSION.intValue == 4)
		_restClientApi = [[ADLRestClientApi4 alloc] init];
	else
		_restClientApi = [[ADLRestClientApi3 alloc] init];
}


- (NSString *)getDownloadUrl:(NSString *)dossierId
                      forPdf:(bool)isPdf {

	return [_restClientApi getDownloadUrl:dossierId
	                               forPdf:isPdf];
}


- (void)downloadDocument:(NSString *)documentId
                   isPdf:(bool)isPdf
                  atPath:(NSURL *)filePath
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


- (NSString *)fixBureauId:(NSString *)dossierId {

	NSString *prefixToRemove = @"workspace://SpacesStore/";

	if ([dossierId hasPrefix:prefixToRemove])
		return [dossierId substringFromIndex:prefixToRemove.length];
	else
		return dossierId;
}


- (NSError *)downloadCertificateUrlWithUrl:(NSString *)url
                                    onPath:(NSString *)localPath {

	NSError *error = nil;

	NSData *urlData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
	if (urlData) {

		NSString *filePath = [NSString stringWithFormat:@"%@/%@",
		                                                localPath,
		                                                url.lastPathComponent];
		[urlData writeToFile:filePath
		          atomically:YES];

		uint64_t fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
		                                                                     error:&error].fileSize;
		NSLog(@"Downloaded - file : %@ (%llu)", filePath, fileSize);
	}
	else {
		error = [[NSError alloc] initWithDomain:url //AFURLRequestSerializationErrorDomain
		                                   code:NSURLErrorBadURL
		                               userInfo:nil];
	}

	return error;
}


#pragma mark API calls


- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure {

	[_restClientApi getApiLevel:^(NSNumber *versionNumber) {
		 success(versionNumber);

		 if (versionNumber.integerValue > PARAPHEUR_API_MAX_VERSION)
			 [ViewUtils logWarningWithMessage:@"Veuillez mettre à jour votre application."
			                                   title:@"La version du i-Parapheur associé à ce compte est trop récente pour cette application."
			                          viewController:nil];
	 }
	                    failure:^(NSError *error) {
		                    failure(error);
	                    }];
}


- (void)getBureaux:(void (^)(NSArray *))success
           failure:(void (^)(NSError *))failure {

	[_restClientApi getBureaux:^(NSArray *bureaux) {
		 success(bureaux);
	 }
	                   failure:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getDossiers:(NSString *)bureau
               page:(int)page
               size:(int)size
             filter:(NSString *)filterJson
            success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

	[_restClientApi getDossiers:[self fixBureauId:bureau]
	                       page:page
	                       size:size
	                     filter:filterJson
	                    success:^(NSArray *dossiers) {
		                    success(dossiers);
	                    }
	                    failure:^(NSError *error) {
		                    failure(error);
	                    }];
}


- (void)getDossier:(NSString *)bureauId
           dossier:(NSString *)dossierId
           success:(void (^)(Dossier *))success
           failure:(void (^)(NSError *))failure {

	[_restClientApi getDossier:[self fixBureauId:bureauId]
	                   dossier:dossierId
	                   success:^(Dossier *dossier) {
		                   success(dossier);
	                   }
	                   failure:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getTypology:(NSString *)bureauId
			success:(void (^)(NSArray *))success
            failure:(void (^)(NSError *))failure {

	[_restClientApi getTypology:bureauId
	                    success:^(NSArray *typeList) {
		                    success(typeList);
	                    }
	                    failure:^(NSError *error) {
		                    failure(error);
	                    }];
}


- (void)getCircuit:(NSString *)dossier
           success:(void (^)(ADLResponseCircuit *))success
           failure:(void (^)(NSError *))failure {

	[_restClientApi getCircuit:dossier
	                   success:^(ADLResponseCircuit *circuits) {
		                   success(circuits);
	                   }
	                   failure:^(NSError *error) {
		                   failure(error);
	                   }];
}


- (void)getAnnotations:(NSString *)dossier
              document:(NSString *)document
               success:(void (^)(NSArray *))success
               failure:(void (^)(NSError *))failure {

	[_restClientApi getAnnotations:dossier
	                      document:document
	                       success:^(NSArray *annotations) {
		                       success(annotations);
	                       }
	                       failure:^(NSError *error) {
		                       failure(error);
	                       }];
}


- (void)addAnnotation:(Annotation *)annotation
           forDossier:(NSString *)dossier
              success:(void (^)(NSArray *))success
              failure:(void (^)(NSError *))failure {

	[_restClientApi actionAddAnnotation:annotation
	                         forDossier:dossier
	                            success:^(NSArray *annotations) {
		                            success(annotations);
	                            }
	                            failure:^(NSError *error) {
		                            failure(error);
	                            }];
}


- (void)updateAnnotation:(Annotation *)annotation
              forDossier:(NSString *)dossier
                 success:(void (^)(NSArray *))success
                 failure:(void (^)(NSError *))failure {

	[_restClientApi actionUpdateAnnotation:annotation
	                            forDossier:dossier
	                               success:^(NSArray *annotations) {
		                               success(annotations);
	                               }
	                               failure:^(NSError *error) {
		                               failure(error);
	                               }];
}


- (void)removeAnnotation:(Annotation *)annotation
              forDossier:(NSString *)dossier
                 success:(void (^)(NSArray *))success
                 failure:(void (^)(NSError *))failure {

	[_restClientApi actionRemoveAnnotation:annotation
	                            forDossier:dossier
	                               success:^(NSArray *annotations) {
		                               success(annotations);
	                               }
	                               failure:^(NSError *error) {
		                               failure(error);
	                               }];
}


- (void)getSignInfoForDossier:(NSString *)dossierId
                    andBureau:(NSString *)bureauId
                      success:(void (^)(ADLResponseSignInfo *))success
                      failure:(void (^)(NSError *))failure {

	[_restClientApi getSignInfoForDossier:dossierId
	                            andBureau:[self fixBureauId:bureauId]
	                              success:^(ADLResponseSignInfo *signInfo) {
		                              success(signInfo);
	                              }
	                              failure:^(NSError *error) {
		                              failure(error);
	                              }];
}


- (void)actionViserForDossier:(NSString *)dossierId
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


- (void)actionSignerForDossier:(NSString *)dossierId
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
	                         withSignature:signature
	                               success:^(NSArray *result) {
		                               success(result);
	                               }
	                               failure:^(NSError *error) {
		                               failure(error);
	                               }];
}


- (void)actionRejeterForDossier:(NSString *)dossierId
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


- (void)actionSwitchToPaperSignatureForDossier:(NSString *)dossierId
                                     forBureau:(NSString *)bureauId
                                       success:(void (^)(NSArray *))success
                                       failure:(void (^)(NSError *))failure {

	[_restClientApi actionSwitchToPaperSignatureForDossier:dossierId
	                                             forBureau:[self fixBureauId:bureauId]
	                                               success:^(NSArray *result) {
		                                               success(result);
	                                               }
	                                               failure:^(NSError *error) {
		                                               failure(error);
	                                               }];
}


@end
