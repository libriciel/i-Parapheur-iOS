
#import "ADLResponseDossiers.h"
#import "ADLStringUtils.h"

@implementation ADLResponseDossiers


+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{@"identifier":@"id"};
}


+ (NSValueTransformer *)isSentJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isSignPapierJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isXemEnabledJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)hasReadJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)readingMandatoryJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)lockedJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)isReadJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)includeAnnexesJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


@end
