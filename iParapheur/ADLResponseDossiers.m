
#import "ADLResponseDossiers.h"
#import "StringUtils.h"

@implementation ADLResponseDossiers


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"identifier":@"id"};
}


+ (NSValueTransformer *)nameJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)protocolJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)actionDemandeeJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)typeJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)bureauNameJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)creatorJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)identifierJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)titleJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)banetteNameJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }
+ (NSValueTransformer *)sousTypeJSONTransformer { return [StringUtils getNullToNilValueTransformer]; }

+ (NSValueTransformer *)isSentJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)isSignPapierJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)isXemEnabledJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)hasReadJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)readingMandatoryJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)lockedJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)isReadJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)includeAnnexesJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }

+ (NSValueTransformer *)documentPrincipalJSONTransformer { return [StringUtils getNullToEmptyDictionaryValueTransformer]; }

+ (NSValueTransformer *)actionsJSONTransformer { return [StringUtils getNullToEmptyArrayValueTransformer]; }

+ (NSValueTransformer *)totalJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)pendingFileJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)skippedJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)dateEmissionJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }
+ (NSValueTransformer *)dateLimiteJSONTransformer { return [StringUtils getNullToZeroValueTransformer]; }

@end
