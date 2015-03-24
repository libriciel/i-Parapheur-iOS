//
//  ADLResponseAnnotations.m
//  iParapheur
//
//

#import "ADLResponseAnnotation.h"
#import "StringUtils.h"

@implementation ADLResponseAnnotation

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{};
}


+ (NSValueTransformer *)dataJSONTransformer { return [StringUtils getNullToEmptyDictionaryValueTransformer]; }


@end
