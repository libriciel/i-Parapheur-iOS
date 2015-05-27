

#import "ADLRestClientApi4.h"

@implementation ADLRestClientApi4


-(NSString *)getAnnotationsUrlForDossier:(NSString*)dossier
							 andDocument:(NSString *)document {

	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/%@/annotations", dossier, document];
}

-(NSString *)getAnnotationUrlForDossier:(NSString*)dossier
							andDocument:(NSString *)document
						andAnnotationId:(NSString *)annotationId {
	
	return [NSString stringWithFormat:@"/parapheur/dossiers/%@/%@/annotations/%@", dossier, document, annotationId];
}


@end
