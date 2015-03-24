
#import "ADLResponseSignInfo.h"
#import "StringUtils.h"

@implementation ADLResponseSignInfo

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{};
}


+ (NSValueTransformer *)signatureInformationsJSONTransformer { return [StringUtils getNullToEmptyDictionaryValueTransformer]; }

@end
