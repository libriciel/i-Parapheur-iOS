/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */
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
