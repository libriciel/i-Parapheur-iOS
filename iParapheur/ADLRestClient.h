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
#import <Foundation/Foundation.h>
#import "ADLRestClientApi4.h"

@interface ADLRestClient : NSObject

@property (nonatomic, strong) ADLRestClientApi3* restClientApi;


+ (id)sharedManager;


- (id)init;


- (void)resetClient;


-(NSNumber *)getRestApiVersion;


-(void)setRestApiVersion:(NSNumber *)apiVersion;


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf;


-(void)downloadDocument:(NSString*)documentId
                  isPdf:(bool)isPdf
				 atPath:(NSURL*)filePath
	            success:(void (^)(NSString *))success
	            failure:(void (^)(NSError *))failure ;


-(NSError *)downloadCertificateUrlWithUrl:(NSString *)url
                                   onPath:(NSString *)localPath;


-(void)getApiLevel:(void (^)(NSNumber *))success
		   failure:(void (^)(NSError *))failure;


-(void)getBureaux:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure;


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
			filter:(NSString*)filterJson
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure;


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(Dossier *))success
		  failure:(void (^)(NSError *))failure;


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure;


-(void)getAnnotations:(NSString*)dossier
			 document:(NSString *)document
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
		  andDocument:(NSString *)document
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;


-(void)updateAnnotation:(NSDictionary*)annotation
				forPage:(int)page
			 forDossier:(NSString *)dossier
			andDocument:(NSString *)document
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure;


-(void)removeAnnotation:(NSDictionary*)annotation
			 forDossier:(NSString *)dossier
			andDocument:(NSString *)document
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure;


-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(ADLResponseSignInfo *))success
					 failure:(void (^)(NSError *))failure;


-(void)actionViserForDossier:(NSString *)dossierId
				   forBureau:(NSString *)bureauId
		withPublicAnnotation:(NSString *)publicAnnotation
	   withPrivateAnnotation:(NSString *)privateAnnotation
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure;


-(void)actionSignerForDossier:(NSString *)dossierId
					forBureau:(NSString *)bureauId
		 withPublicAnnotation:(NSString *)publicAnnotation
		withPrivateAnnotation:(NSString *)privateAnnotation
				withSignature:(NSString *)signature
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure;


-(void)actionRejeterForDossier:(NSString *)dossierId
					 forBureau:(NSString *)bureauId
		  withPublicAnnotation:(NSString *)publicAnnotation
		 withPrivateAnnotation:(NSString *)privateAnnotation
					   success:(void (^)(NSArray *))success
					   failure:(void (^)(NSError *))failure;


- (void)actionSwitchToPaperSignatureForDossier:(NSString *)dossierId
                                     forBureau:(NSString *)bureauId
                                       success:(void (^)(NSArray *))success
                                       failure:(void (^)(NSError *))failure;


@end
