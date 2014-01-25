//
//  ADLAPIHelper.h
//  iParapheur
//
//  Created by Jason MAIRE on 24/01/2014.
//
//

#import <Foundation/Foundation.h>

@interface ADLAPIHelper : NSObject

+ (NSString*) actionNameForAction:(NSString*) action;

+ (NSArray*) actionsForDossier:(NSDictionary*) dossier;

@end
