//
//  ADLResponseAnnotations.h
//  iParapheur
//
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


static NSString *const kRAData = @"data";
static NSString *const kRAIdDossier = @"idDossier";
static NSString *const kRAIdAnnotation = @"idAnnotation";


@interface ADLResponseAnnotation : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSString *idDossier;
@property (nonatomic, strong) NSString *idAnnotation;


@end
