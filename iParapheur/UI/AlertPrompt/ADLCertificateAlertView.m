/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#import "ADLCertificateAlertView.h"


@implementation ADLCertificateAlertView

@synthesize p12Path;


- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];

	if (self) {
		// Initialization code
	}

	return self;
}


- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ... {

	self = [super initWithTitle:title
	                    message:message
	                   delegate:delegate
	          cancelButtonTitle:cancelButtonTitle
	          otherButtonTitles:otherButtonTitles, nil];

	if (self)
		self.alertViewStyle = UIAlertViewStyleSecureTextInput;

	return self;
}

@end
