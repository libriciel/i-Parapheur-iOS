//
//  ADLResponseCircuit.m
//  iParapheur
//
//

#import "ADLResponseCircuit.h"
#import "StringUtils.h"


@implementation ADLResponseCircuit


- (void)setEtapes:(NSArray *)etapes {

	NSMutableArray *etapesMutableArray = [NSMutableArray new];

	for (NSDictionary *etape in etapes)
		[etapesMutableArray addObject:[StringUtils nilifyDictionaryValues:etape]];

	_etapes = etapesMutableArray;
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {

	return @{
			kRCEtapes : kRCEtapes,
			kRCAnnotPriv : kRCAnnotPriv,
			kRCIsDigitalSignatureMandatory : kRCIsDigitalSignatureMandatory,
			kRCHasSelectionScript : kRCHasSelectionScript,
			kRCSigFormat : kRCSigFormat
	};
}


+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {

	// Tests

	BOOL isStringKey = [StringUtils doesArray:@[kRCSigFormat, kRCAnnotPriv]
	                           containsString:key];

	BOOL isBooleanKey = [StringUtils doesArray:@[kRCIsDigitalSignatureMandatory, kRCHasSelectionScript]
	                            containsString:key];

	BOOL isDictionaryKey = [key isEqualToString:kRCEtapes];

	// Return proper Transformer

	if (isStringKey)
		return [StringUtils getNullToNilValueTransformer];
	else if (isBooleanKey)
		return [StringUtils getNullToFalseValueTransformer];
	else if (isDictionaryKey)
		return [StringUtils getNullToEmptyDictionaryValueTransformer];

	NSLog(@"ADLResponseCircuit, unknown parameter : %@", key);
	return nil;
}


@end
