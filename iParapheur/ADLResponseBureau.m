
#import "ADLResponseBureau.h"
#import "ADLStringUtils.h"


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
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)hasSecretaireJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isSecretaireJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


@end
