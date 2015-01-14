//
//  ADLResponseCircuit.h
//  iParapheur
//
//

#import <Foundation/Foundation.h>

@interface ADLResponseCircuit : NSObject

@property (nonatomic, strong) NSArray *etapes;
@property (nonatomic, strong) NSString *annotPriv;
@property (nonatomic) bool isDigitalSignatureMandatory;
@property (nonatomic) bool hasSelectionScript;
@property (nonatomic, strong) NSString *sigFormat;

@end