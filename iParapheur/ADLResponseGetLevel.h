
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


static NSString *const kGLLevel = @"level";


@interface ADLResponseGetLevel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *level;

@end
