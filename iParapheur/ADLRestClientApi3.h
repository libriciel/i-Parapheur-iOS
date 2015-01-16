
#import <Foundation/Foundation.h>

@interface ADLRestClientApi3 : NSObject


-(id)init;


-(NSString *)getDownloadUrl:(NSString *)dossierId;


-(void)getApiLevel:(void (^)(NSNumber *versionNumber))success
            failure:(void (^)(NSError *error))failure;


-(void)getBureaux:(void (^)(NSArray *bureaux))success
           failure:(void (^)(NSError *error))failure;


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure;


-(void)getDossier:(NSString*)bureau
		  dossier:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure;


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure;


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;


-(void)addAnnotation:(NSDictionary*)annotation
		  forDossier:(NSString *)dossier
			 success:(void (^)(NSArray *))success
			 failure:(void (^)(NSError *))failure;


-(void)updateAnnotation:(NSDictionary*)annotation
			 forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure;


@end
