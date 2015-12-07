//
//  ADLResponseCircuit.h
//  iParapheur
//
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"


static NSString *const kRCEtapes = @"etapes";
static NSString *const kRCAnnotPriv = @"annotPriv";
static NSString *const kRCIsDigitalSignatureMandatory = @"isDigitalSignatureMandatory";
static NSString *const kRCHasSelectionScript = @"hasSelectionScript";
static NSString *const kRCSigFormat = @"sigFormat";


@interface ADLResponseCircuit : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSArray *etapes;
@property (nonatomic, strong) NSString *annotPriv;
@property (nonatomic) bool isDigitalSignatureMandatory;
@property (nonatomic) bool hasSelectionScript;
@property (nonatomic, strong) NSString *sigFormat;

@end