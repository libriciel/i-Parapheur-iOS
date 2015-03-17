
#import <Foundation/Foundation.h>
#import <Mantle.h>

@interface ADLResponseSignInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *signatureInformations;

@end
