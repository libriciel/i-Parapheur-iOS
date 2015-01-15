
#import <Foundation/Foundation.h>
#import "ADLRestClientApi3.h"

@interface ADLRestClient : NSObject

@property (nonatomic, strong) ADLRestClientApi3* restClientApi3;


- (id)init;


-(NSString *)getDownloadUrl:(NSString *)dossierId;
	

-(void)getApiLevel:(void (^)(NSNumber *))success
		   failure:(void (^)(NSError *))failure;


-(void)getBureaux:(void (^)(NSArray *))success
		  failure:(void (^)(NSError *))failure;


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


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure;

@end
