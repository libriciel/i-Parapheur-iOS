
#import <Foundation/Foundation.h>
#import <MTLValueTransformer.h>


@interface StringUtils : NSObject

+ (NSDictionary *)nilifyDictionaryValues:(NSDictionary *)dictionary;

+ (BOOL)doesString:(NSString*)string
 containsSubString:(NSString*)substring;

+ (BOOL)doesArray:(NSArray *)array
   containsString:(NSString *)string;

+ (NSString *)getErrorMessage:(NSError *)error;

+ (MTLValueTransformer *)getNullToFalseValueTransformer;

+ (MTLValueTransformer *)getNullToNilValueTransformer;

+ (MTLValueTransformer *)getNullToZeroValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyDictionaryValueTransformer;

+ (MTLValueTransformer *)getNullToEmptyArrayValueTransformer;


@end
