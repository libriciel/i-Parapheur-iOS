//
//  ADLResponseDossier.m
//  iParapheur
//
//

#import "ADLResponseDossier.h"
#import "StringUtils.h"

@implementation ADLResponseDossier


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"identifier":@"id"};
}

+ (NSValueTransformer *)includeAnnexesJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)lockedJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)readingMandatoryJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isReadJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isSignPapierJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)hasReadJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isXemEnabledJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)canAddJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isSentJSONTransformer {
	return [StringUtils getNullToFalseValueTransformer];
}




@end
