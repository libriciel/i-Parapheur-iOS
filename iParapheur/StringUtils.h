
#import <Foundation/Foundation.h>
#import <Mantle.h>


@interface StringUtils : NSObject

+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary;

+ (BOOL)doesString:(NSString*)string
 containsSubString:(NSString*)substring;

+ (NSString *)getErrorMessage:(NSError *)error;

+ (MTLValueTransformer *)getNullToFalseValueTransformer;

+ (MTLValueTransformer *)getNullToNilValueTransformer;

+ (MTLValueTransformer *)getNullToZeroValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer;

@end
