//
//  UIColor+CustomColors.m
//  iParapheur
//
//  Created by Jason MAIRE on 22/01/2014.
//
//

#import "UIColor+CustomColors.h"

@implementation UIColor (CustomColors)

+(UIColor*) darkGreenColor {
    return [UIColor colorWithRed:0.2f green:0.7f blue:0.2f alpha:1.0f];
}

+(UIColor*) darkRedColor {
    return [UIColor colorWithRed:0.7f green:0.2f blue:0.2f alpha:1.0f];
}

+(UIColor*) darkBlueColor {
    return [UIColor colorWithRed:0.2f green:0.2f blue:0.7f alpha:1.0f];
}

+(UIColor*) defaultTintColor {
    return [UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f];
}

+(UIColor*) colorForAction:(NSString*) action {
    if ([action isEqualToString:@"VISER"] || [action isEqualToString:@"SIGNER"]) {
        return [UIColor darkGreenColor];
    }
    else if ([action isEqualToString:@"REJETER"]) {
        return [UIColor darkRedColor];
    }
    else if ([action isEqualToString:@"ARCHIVER"]) {
        return [UIColor blackColor];
    }
    
    return [UIColor darkBlueColor];
}

@end
