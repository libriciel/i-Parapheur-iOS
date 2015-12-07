#import "ADLResponseSignInfo.h"
#import "StringUtils.h"


@implementation ADLResponseSignInfo



+ (NSDictionary *)JSONKeyPathsByPropertyKey {
	return @{kSISignatureInformations : kSISignatureInformations};
}


+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {

	if ([key isEqualToString:kSISignatureInformations])
		return [StringUtils getNullToEmptyDictionaryValueTransformer];

	return nil;
}

@end
