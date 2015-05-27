
#import <Foundation/Foundation.h>
#import <AFHTTPSessionManager.h>
#import "ADLResponseDossier.h"
#import "ADLResponseSignInfo.h"
#import "ADLResponseCircuit.h"


@interface ADLRestClientApi3 : NSObject


@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;


-(id)init;


-(id)initWithLogin:(NSString*)login
		  password:(NSString*)password
			   url:(NSString*)url;


-(void)cancelAllOperations;


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf;


-(void)getApiLevel:(void (^)(NSNumber *versionNumber))success
		   failure:(void (^)(NSError *error))failure;


-(void)getBureaux:(void (^)(NSArray *bureaux))success
		  failure:(void (^)(NSError *error))failure;


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
			filter:(NSString*)filterJson
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure;


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(ADLResponseDossier *))success
		  failure:(void (^)(NSError *))failure;


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure;


-(void)getAnnotations:(NSString*)dossier
			 document:(NSString*)document
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


-(void)actionAddAnnotation:(NSDictionary*)annotation
				forDossier:(NSString *)dossier
			   andDocument:(NSString *)document
				   success:(void (^)(NSArray *))success
				   failure:(void (^)(NSError *))failure;


-(void)actionUpdateAnnotation:(NSDictionary*)annotation
					  forPage:(int)page
				   forDossier:(NSString *)dossier
				  andDocument:(NSString *)document
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure;


-(void)actionRemoveAnnotation:(NSDictionary*)annotation
				   forDossier:(NSString *)dossier
				  andDocument:(NSString *)document
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure;


-(void)downloadDocument:(NSString*)documentId
                  isPdf:(bool)isPdf
	             atPath:(NSURL*)filePath
	            success:(void (^)(NSString *))success
	            failure:(void (^)(NSError *))failure;

@end
