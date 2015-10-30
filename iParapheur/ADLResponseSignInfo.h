
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


static NSString *const kSISignatureInformations = @"signatureInformations";


@interface ADLResponseSignInfo : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSDictionary *signatureInformations;

@end
