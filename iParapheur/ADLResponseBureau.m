
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


+ (NSValueTransformer *)levelJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)enPreparationJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)enRetardJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)aArchiverJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)aTraiterJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)dossiersDeleguesJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)retournesJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }

+ (NSValueTransformer *)showAVenirJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)hasSecretaireJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)isSecretaireJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }

+ (NSValueTransformer *)habilitationJSONTransformer { return [StringUtils getNullToEmptyDictionaryValueTransformer]; }

+ (NSValueTransformer *)descJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)collectiviteJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)nodeRefJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)identifierJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)imageJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)shortNameJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)nameJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }

@end
