
#import "ADLResponseBureau.h"
#import "StringUtils.h"



@implementation ADLResponseBureau


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"desc":@"description",
			 @"enPreparation":@"en-preparation",
			 @"enRetard":@"en-retard",
			 @"showAVenir":@"show_a_venir",
			 @"aArchiver":@"a-archiver",
			 @"aTraiter":@"a-traiter",
			 @"identifier":@"id",
			 @"dossiersDelegues":@"dossier-delegues"};
}


+ (NSValueTransformer *)showAVenirJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)hasSecretaireJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isSecretaireJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}




@end
