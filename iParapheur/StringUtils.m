
#import "StringUtils.h"

@implementation StringUtils


+ (NSDictionary *) nilifyValuesOfDictionary:(NSDictionary *)dictionary {
	
	NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
	
	for (NSString* key in dictionary) {
		
		id value = [dictionary objectForKey:key];
		
		if ((value == NULL) || ([value isEqual:[NSNull null]]))
			[mutableDictionary setValue:nil
								 forKey:key];
		else
			[mutableDictionary setValue:[dictionary objectForKey:key]
								 forKey:key];
	}
	
	return mutableDictionary;
}


+ (MTLValueTransformer *)getNullToFalseValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSNumber numberWithInteger: 0];
		else
			return inObj;
	}];
}


@end
