
#import <Foundation/Foundation.h>
#import <Mantle.h>


@interface StringUtils : NSObject

+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary;

+ (MTLValueTransformer *)getNullToFalseValueTransformer;

+ (MTLValueTransformer *)getNullToNilValueTransformer;

+ (MTLValueTransformer *)getNullToZeroValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer;

@end
