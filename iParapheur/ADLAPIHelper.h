//
//  ADLAPIHelper.h
//  iParapheur
//
//  Created by Jason MAIRE on 24/01/2014.
//
//

#import <Foundation/Foundation.h>
#import "ADLResponseDossier.h"

@interface ADLAPIHelper : NSObject

+ (NSString*) actionNameForAction:(NSString*) action;

+ (NSArray*) actionsForADLResponseDossier:(ADLResponseDossier*) dossier;

+ (NSArray*) actionsForDossier:(NSDictionary*) dossier;

@end
