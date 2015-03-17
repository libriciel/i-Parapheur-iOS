//
//  ADLResponseAnnotations.h
//  iParapheur
//
//

#import <Foundation/Foundation.h>
#import "Mantle.h"

@interface ADLResponseAnnotation : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSString *idDossier;
@property (nonatomic, strong) NSString *idAnnotation;


@end
