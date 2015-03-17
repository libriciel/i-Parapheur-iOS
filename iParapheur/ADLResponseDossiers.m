
#import "ADLResponseDossiers.h"
#import "StringUtils.h"

@implementation ADLResponseDossiers


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"identifier":@"id"};
}

+ (NSValueTransformer *)isSentJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isSignPapierJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isXemEnabledJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)hasReadJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)readingMandatoryJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)lockedJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isReadJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)includeAnnexesJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}



@end
