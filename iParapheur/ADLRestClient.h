
#import <Foundation/Foundation.h>
#import "ADLRestClientApi3.h"

@interface ADLRestClient : NSObject

@property (nonatomic, strong) ADLRestClientApi3* restClientApi3;


+ (id)sharedManager;


- (id)init;


- (void)reset;


+(NSNumber *)getRestApiVersion;


+(void)setRestApiVersion:(NSNumber *)apiVersion;


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf;
	

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
		  success:(void (^)(ADLResponseDossier *))success
		  failure:(void (^)(NSError *))failure;


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure;


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;


-(void)updateAnnotation:(NSDictionary*)annotation
				forPage:(int)page
			 forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure;


-(void)removeAnnotation:(NSDictionary*)annotation
			 forDossier:(NSString *)dossier
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


@end
