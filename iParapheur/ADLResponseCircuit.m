//
//  ADLResponseCircuit.m
//  iParapheur
//
//

#import "ADLResponseCircuit.h"
#import "ADLStringUtils.h"

@implementation ADLResponseCircuit

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{};
}


+ (NSValueTransformer *)isDigitalSignatureMandatoryJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}


+ (NSValueTransformer *)hasSelectionScriptJSONTransformer {
	return [ADLStringUtils getNullToFalseValueTransformer];
}
	
@end
