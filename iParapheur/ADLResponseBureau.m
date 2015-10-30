#import "ADLResponseBureau.h"
#import "StringUtils.h"


@implementation ADLResponseBureau


+ (NSDictionary *)JSONKeyPathsByPropertyKey {

	return @{
			kBLevel : kBLevel,
			kBHasSecretaire : kBHasSecretaire,
			kBCollectivite : kBCollectivite,
			kBNodeRef : kBNodeRef,
			kBShortName : kBShortName,
			kBImage : kBImage,
			kBHabilitation : kBHabilitation,
			kBIsSecretaire : kBIsSecretaire,
			kBHabilitation : kBHabilitation,
			kBIsSecretaire : kBIsSecretaire,
			kBName : kBName,
			kBRetournes : kBRetournes,
			kBDesc : @"description",
			kBEnPreparation : @"en-preparation",
			kBEnRetard : @"en-retard",
			kBShowAVenir : @"show_a_venir",
			kBAArchiver : @"a-archiver",
			kBATraiter : @"a-traiter",
			kBIdentifier : @"id",
			kBDossiersDelegues : @"dossier-delegues"
	};
}


+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {

	// Tests

	BOOL isStringKey = [StringUtils doesArray:@[kBDesc, kBCollectivite, kBNodeRef, kBIdentifier, kBImage, kBShortName, kBName]
	                           containsString:key];

	BOOL isBooleanKey = [StringUtils doesArray:@[kBShowAVenir, kBHasSecretaire, kBIsSecretaire]
	                            containsString:key];

	BOOL isIntegerKey = [StringUtils doesArray:@[kBLevel, kBEnPreparation, kBEnRetard, kBAArchiver, kBATraiter, kBDossiersDelegues, kBRetournes]
	                            containsString:key];

	BOOL isDictionaryKey = [key isEqualToString:kBHabilitation];

	// Return proper Transformer

	if (isStringKey)
		return [StringUtils getNullToNilValueTransformer];
	else if (isBooleanKey)
		return [StringUtils getNullToFalseValueTransformer];
	else if (isIntegerKey)
		return [StringUtils getNullToZeroValueTransformer];
	else if (isDictionaryKey)
		return [StringUtils getNullToEmptyDictionaryValueTransformer];

	NSLog(@"ADLResponseBureau, unknown parameter : %@", key);
	return nil;
}


@end
