/*
 * Copyright 2012-2016, Adullact-Projet.
 * Contributors : SKROBS (2012)
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

#import "RGLoginViewController.h"
#import "ADLRestClient.h"
#import "iParapheur-Swift.h"
#import "StringUtils.h"


@interface RGLoginViewController ()

@end

@implementation RGLoginViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGLoginViewController");

	_doneButton.target = self;
	_doneButton.action = @selector(onValidateButtonClicked);

	_backButton.target = self;
	_backButton.action = @selector(onBackButtonClicked);

	// Load registered values

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

	_loginTextField.text = [preferences objectForKey:@"settings_login"];
	_passwordTextField.text = [preferences objectForKey:@"settings_password"];
	_serverUrlTextField.text = [preferences objectForKey:@"settings_server_url"];
}


- (void) viewWillAppear:(BOOL)animated {

	// Change value events

	[_loginTextField addTarget:self
						action:@selector(onTextFieldValueChanged)
			  forControlEvents:UIControlEventEditingChanged];

	[_passwordTextField addTarget:self
						   action:@selector(onTextFieldValueChanged)
				 forControlEvents:UIControlEventEditingChanged];

	[_serverUrlTextField addTarget:self
							action:@selector(onTextFieldValueChanged)
				  forControlEvents:UIControlEventEditingChanged];

	[super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


- (void)viewWillDisappear:(BOOL)animated {

	[_loginTextField removeTarget:nil
						   action:NULL
				 forControlEvents:UIControlEventAllEvents];

	[_passwordTextField removeTarget:nil
							  action:NULL
					forControlEvents:UIControlEventAllEvents];

	[_serverUrlTextField removeTarget:nil
							   action:NULL
					 forControlEvents:UIControlEventAllEvents];

	[super viewWillDisappear:animated];
}

#pragma mark - Private methods


- (void)viewWillLayoutSubviews{
	[super viewWillLayoutSubviews];
	self.view.superview.bounds = CGRectMake(0, 0, 550, 350);
}


- (BOOL)validateFieldsForConnnectionEvent:(BOOL)connectionEvent {

	NSString *properServerTextFieldValue = [self cleanupServerName:_serverUrlTextField.text];

	BOOL loginTextFieldValid = (_loginTextField.text.length != 0);
	BOOL passwordTextFieldValid = (_passwordTextField.text.length != 0);
	BOOL serverTextFieldValid = (properServerTextFieldValue.length != 0);

	// Set orange background on text fields.
	// only on connection event, not on change value events

	[self setBorderOnTextField:_loginTextField
					 withAlert:(!loginTextFieldValid && connectionEvent)];

	[self setBorderOnTextField:_passwordTextField
					 withAlert:(!passwordTextFieldValid && connectionEvent)];

	[self setBorderOnTextField:_serverUrlTextField
					 withAlert:(!serverTextFieldValid && connectionEvent)];


	return (loginTextFieldValid && passwordTextFieldValid && serverTextFieldValid);
}


- (void)setBorderOnTextField:(UITextField *)textField
                   withAlert:(BOOL)alert {

	if (alert) {
		textField.layer.cornerRadius = 6.0f;
		textField.layer.masksToBounds = YES;
		textField.layer.borderWidth = 1.0f;
		textField.layer.borderColor = [[ColorUtils DarkOrange] CGColor];
		textField.backgroundColor = [[ColorUtils DarkOrange] colorWithAlphaComponent:0.1];
	} else {
		textField.layer.borderColor = [[UIColor clearColor] CGColor];
		textField.backgroundColor = [UIColor clearColor];
	}
}


- (void)testConnection {

	if (_restClient)
		[_restClient cancelAllOperations];

	NSString *properServerTextFieldValue = [self cleanupServerName:_serverUrlTextField.text];
	_restClient = [[ADLRestClientApi3 alloc] initWithLogin:_loginTextField.text
												  password:_passwordTextField.text
													   url:properServerTextFieldValue];

	[self enableInterface:FALSE];

	__weak typeof(self) weakSelf = self;
	[_restClient getApiLevel:^(NSNumber *versionNumber) {
						__strong typeof(weakSelf) strongSelf = weakSelf;
						if (strongSelf) {
							[strongSelf enableInterface:TRUE];
							[strongSelf dismissWithSuccess:TRUE];
						}
					 }
					 failure:^(NSError *error) {
						 __strong typeof(weakSelf) strongSelf = weakSelf;
						 if (strongSelf) {
							 [strongSelf enableInterface:TRUE];

							 if (error.code == kCFURLErrorUserAuthenticationRequired) {
								 [strongSelf setBorderOnTextField:_loginTextField withAlert:TRUE];
								 [strongSelf setBorderOnTextField:_passwordTextField withAlert:TRUE];
							 }
							 else {
								 [strongSelf setBorderOnTextField:_serverUrlTextField withAlert:TRUE];
							 }

 						 NSString *localizedDescription = [StringUtils getErrorMessage:error];

							 if ([error.localizedDescription isEqualToString:localizedDescription])
								 _errorTextField.text = [NSString stringWithFormat:@"La connexion au serveur a échoué (code %ld)", (long)error.code];
							 else
								 _errorTextField.text = localizedDescription;
						 }
					 }];
}


- (void)dismissWithSuccess:(BOOL)success {

	if (_restClient)
		[_restClient cancelAllOperations];

	// Saving proper data

	if (success) {
		NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
		NSString *properServerTextFieldValue = [self cleanupServerName:_serverUrlTextField.text];

		[preferences setObject:_loginTextField.text
						forKey:@"settings_login"];

		[preferences setObject:_passwordTextField.text
						forKey:@"settings_password"];

		[preferences setObject:properServerTextFieldValue
						forKey:@"settings_server_url"];
	}

	// Reset RestClient values

	[[ADLRestClient sharedManager] resetClient];

	//

	[self.presentingViewController dismissViewControllerAnimated:YES
													  completion:nil];

	NSDictionary *userInfo = @{@"success": @(success)};

 	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginPopupDismiss"
														object:nil
													  userInfo:userInfo];
}


- (NSString *)cleanupServerName:(NSString *)url {

	// Removing space
	// TODO Adrien : add special character restrictions tests ?

	url = [url stringByReplacingOccurrencesOfString:@" "
										 withString:@""];

	// Getting the server name
	// Regex :	- ignore everything before "://" (if exists)					^(?:.*:\/\/)*
	//			- then ignore following "m." (if exists)						(?:m\.)*
	//			- then catch every char but "/"									([^\/]*)
	//			- then, ignore everything after the first "/" (if exists)		(?:\/.*)*$
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(?:.*:\\/\\/)*(?:m\\.)*([^\\/]*)(?:\\/.*)*$"
																		   options:NSRegularExpressionCaseInsensitive
																			 error:nil];

	NSTextCheckingResult *match = [regex firstMatchInString:url
													options:0
													  range:NSMakeRange(0, [url length])];

	if (match)
		url = [url substringWithRange:[match rangeAtIndex:1]];

	return url;
}


- (void)enableInterface:(BOOL)enabled {

	_loginTextField.enabled = enabled;
	_passwordTextField.enabled = enabled;
	_serverUrlTextField.enabled = enabled;

	_errorTextField.hidden = !enabled;

	if (enabled)
		[_activityIndicatorView stopAnimating];
	else
		[_activityIndicatorView startAnimating];
}


#pragma mark - UI callback


- (void)onTextFieldValueChanged {
	_errorTextField.text = @"";
	[self validateFieldsForConnnectionEvent:FALSE];
}


- (void)onBackButtonClicked {
	[self dismissWithSuccess:FALSE];
}


- (void)onValidateButtonClicked {

	// Test connection

	if ([self validateFieldsForConnnectionEvent:TRUE])
		[self testConnection];
}


@end
