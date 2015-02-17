
#import "ADLStringUtils.h"
#import <Mantle.h>

@implementation ADLStringUtils


+ (MTLValueTransformer *)getNullToFalseValueTransformer {
	return [MTLValueTransformer transformerWithBlock:^id(id inObj) {
		if (inObj == nil || inObj == [NSNull null])
			return [NSNumber numberWithInteger: 0];
		else
			return inObj;
	}];
}


@end
