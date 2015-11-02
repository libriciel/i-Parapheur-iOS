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
	return [UIColor colorWithRed:11.0f/255.0f
						   green:211.0f/255.0f
							blue:24.0f/255.0f
						   alpha:1.0f]; // #0BD318
}


+(UIColor*) darkRedColor {
	return [UIColor colorWithRed:255.0f/255.0f
						   green:56.0f/255.0f
							blue:36.0f/255.0f
						   alpha:1]; // #FF3824
}


+(UIColor*) darkOrangeColor {
	return [UIColor colorWithRed:255.0f/255.0f
						   green:150.0f/255.0f
							blue:0.0f/255.0f
						   alpha:1]; // #FF9600
}


+(UIColor*) darkYellowColor {
	return [UIColor colorWithRed:255.0f/255.0f
						   green:205.0f/255.0f
							blue:0.0f/255.0f
						   alpha:1]; // #FFCD00
}


+(UIColor*) darkPurpleColor {
	return [UIColor colorWithRed:198.0f/255.0f
						   green:68.0f/255.0f
							blue:252.0f/255.0f
						   alpha:1]; // #C644FC
}


+(UIColor*) darkBlueColor {
	return [UIColor colorWithRed:0.0f/255.0f
						   green:118.0f/255.0f
							blue:255.0f/255.0f
						   alpha:1.0f]; // #0076FF
}


+(UIColor*) selectedCellGreyColor {
	return [UIColor colorWithRed:217.0f/255.0f
						   green:217.0f/255.0f
							blue:217.0f/255.0f
						   alpha:1.0f]; // #D9D9D9
}


+(UIColor*) defaultTintColor {
    return [self darkBlueColor];
}


+(UIColor*) colorForAction:(NSString*) action {

	if ([action isEqualToString:@"VISER"] || [action isEqualToString:@"SIGNER"])
        return [UIColor darkGreenColor];
    else if ([action isEqualToString:@"REJETER"])
        return [UIColor darkRedColor];
    else if ([action isEqualToString:@"ARCHIVER"])
        return [UIColor blackColor];
	else
		return [UIColor lightGrayColor];
}


@end
