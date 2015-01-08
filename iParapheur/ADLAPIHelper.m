//
//  ADLAPIHelper.m
//  iParapheur
//
//  Created by Jason MAIRE on 24/01/2014.
//
//

#import "ADLAPIHelper.h"

@implementation ADLAPIHelper


+ (NSString*) actionNameForAction:(NSString*) action {
    if ([action isEqualToString:@"VISER"] || [action isEqualToString:@"VISA"]) {
        return @"Viser";
    }
    else if ([action isEqualToString:@"SIGNER"] || [action isEqualToString:@"SIGNATURE"]) {
        return  @"Signer";
    }
    else if ([action isEqualToString:@"TDT"]) {
        return  @"Envoyer au Tdt";
    }
    else if ([action isEqualToString:@"MAILSEC"]) {
        return  @"Envoyer par mail sécurisé";
    }
    else if ([action isEqualToString:@"ARCHIVER"] || [action isEqualToString:@"ARCHIVAGE"]) {
        return  @"Archiver";
    }
    else if ([action isEqualToString:@"SECRETARIAT"]) {
        return  @"Envoyer au secrétariat";
    }
    else if ([action isEqualToString:@"SUPPRIMER"]) {
        return  @"Supprimer";
    }
    else if ([action isEqualToString:@"REJETER"]) {
        return  @"Rejeter";
    }
    else if ([action isEqualToString:@"REMORD"]) {
        return  @"Récupérer";
    }
    return nil;
}


+ (NSArray*) actionsForDossier:(NSDictionary*) dossier {
    
    NSMutableArray *actions = [NSMutableArray new];
    NSDictionary *returnedActions = [dossier objectForKey:@"actions"];
    NSString *actionDemandee = [dossier objectForKey:@"actionDemandee"];
    
    for (NSString *action in [returnedActions allKeys]) {
        BOOL isActionEnabled = [[returnedActions objectForKey:action] boolValue];
        
        if (isActionEnabled) {
            if ([action isEqualToString:@"archive"]) {
                if ([actionDemandee isEqualToString:@"ARCHIVAGE"]) {
                    [actions addObject:@"ARCHIVER"];
                }
            }
            else if ([action isEqualToString:@"delete"]) {
                [actions addObject:@"SUPPRIMER"];
            }
            else if ([action isEqualToString:@"reject"]) {
                [actions addObject:@"REJETER"];
            }
            else if ([action isEqualToString:@"remorse"]) {
                [actions addObject:@"REMORD"];
            }
            else if ([action isEqualToString:@"secretary"]) {
                [actions addObject:@"SECRETARIAT"];
            }
            else if ([action isEqualToString:@"sign"]) {
                if ([actionDemandee isEqualToString:@"SIGNATURE"]) {
                    [actions addObject:@"SIGNER"];
                }
                else if ([actionDemandee isEqualToString:@"VISA"]) {
                    [actions addObject:@"VISER"];
                }
                else if ([actionDemandee isEqualToString:@"TDT"]) {
                    [actions addObject:@"TDT"];
                }
                else if ([actionDemandee isEqualToString:@"MAILSEC"]) {
                    [actions addObject:@"MAILSEC"];
                }
            }
        }
    }
    return [NSArray arrayWithArray:actions];
}


@end
