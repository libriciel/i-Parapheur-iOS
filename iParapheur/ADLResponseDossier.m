//
//  ADLResponseDossier.m
//  iParapheur
//
//

#import "ADLResponseDossier.h"
#import "ADLStringUtils.h"

@implementation ADLResponseDossier


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"identifier":@"id"};
}

+ (NSValueTransformer *)includeAnnexesJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)lockedJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)readingMandatoryJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isReadJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isSignPapierJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)hasReadJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isXemEnabledJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)canAddJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}

+ (NSValueTransformer *)isSentJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


@end
