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

@end
