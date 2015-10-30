//
//  ADLResponseAnnotations.m
//  iParapheur
//
//

#import "ADLResponseAnnotation.h"


@implementation ADLResponseAnnotation

+ (NSDictionary*)JSONKeyPathsByPropertyKey {

	return @{
			kRAData : kRAData,
			kRAIdDossier : kRAIdDossier,
			kRAIdAnnotation : kRAIdAnnotation
	};
}

@end
