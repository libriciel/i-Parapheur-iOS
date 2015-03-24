//
//  ADLResponseCircuit.m
//  iParapheur
//
//

#import "ADLResponseCircuit.h"
#import "StringUtils.h"


@implementation ADLResponseCircuit

- (void)setEtapes:(NSArray *)etapes {
	
	NSMutableArray *etapesMutableArray = [[NSMutableArray alloc] init];
	
	for (NSDictionary* etape in etapes)
		[etapesMutableArray addObject:[StringUtils nilifyValuesOfDictionary:etape]];

	_etapes = etapesMutableArray;
}

+ (NSDictionary*)JSONKeyPathsByPropertyKey {
	return @{};
}


+ (NSValueTransformer *)isDigitalSignatureMandatoryJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }
+ (NSValueTransformer *)hasSelectionScriptJSONTransformer { return [StringUtils getNullToFalseValueTransformer]; }

+ (NSValueTransformer *)etapesJSONTransformer { return [StringUtils getNullToEmptyArrayValueTransformer]; }


@end
