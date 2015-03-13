//
//  RGSplashscreenViewController.m
//  iParapheur
//
//

#import "RGLoginViewController.h"
#import "AJNotificationView.h"
#import "ADLRestClient.h"
#import "UIColor+CustomColors.h"


@interface RGLoginViewController ()

@end

@implementation RGLoginViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : SplashScreenViewController");
	
	_doneButton.target = self;
	_doneButton.action = @selector(onValidateButtonClicked);
	
	_backButton.target = self;
	_backButton.action = @selector(onBackButtonClicked);
	
	// Load registered values
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

	_loginTextField.text = [preferences objectForKey:@"settings_login"];
	_passwordTextField.text = [preferences objectForKey:@"settings_password"];
	_serverUrlTextField.text = [preferences objectForKey:@"settings_server_url"];
	
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
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


#pragma mark - Private methods


- (BOOL)validateFieldsForConnnectionEvent:(BOOL)connectionEvent {
	
	BOOL loginTextFieldValid = (_loginTextField.text.length != 0);
	BOOL passwordTextFieldValid = (_passwordTextField.text.length != 0);
	BOOL serverTextFieldValid = (_serverUrlTextField.text.length != 0);
	
	// TODO Adrien : add special character restrictions tests, and url format validation field test
	
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
		
		textField.layer.cornerRadius=6.0f;
		textField.layer.masksToBounds=YES;
		textField.layer.borderWidth= 1.0f;
		textField.layer.borderColor=[[UIColor orangeColor] CGColor];
		
		textField.backgroundColor=[UIColor colorWithRed:255.0/255.0
												  green:150.0/255.0
												   blue:0.0/255.0
												  alpha:0.1];
	}
	else {
		textField.layer.borderColor = [[UIColor clearColor]CGColor];
		textField.backgroundColor = [UIColor clearColor];
	}
}


- (void)testConnection {

	ADLRestClient *restClient = [[ADLRestClient alloc] init];
	[self enableInterface:FALSE];
	
	[restClient getApiLevel:^(NSNumber *versionNumber) {
						[self enableInterface:TRUE];
		
						// Saving
		
						NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
		
						[preferences setObject:_loginTextField.text
										forKey:@"settings_valid_login"];
		
						[preferences setObject:_passwordTextField.text
										forKey:@"settings_valid_password"];
		
						[preferences setObject:_serverUrlTextField.text
										forKey:@"settings_valid_server_url"];
		
						// Exit
		
						[self dismissWithSuccess:TRUE];
					}
					failure:^(NSError *error) {
						[self enableInterface:TRUE];

						if (error.code == kCFURLErrorUserAuthenticationRequired) {
							[self setBorderOnTextField:_loginTextField withAlert:TRUE];
							[self setBorderOnTextField:_passwordTextField withAlert:TRUE];
							_errorText.text = @"Echec d'authentification";
						}
						else if (error.code == kCFURLErrorCannotFindHost) {
							[self setBorderOnTextField:_serverUrlTextField withAlert:TRUE];
							_errorText.text = error.localizedDescription;
						}
					 }];
}


- (void)dismissWithSuccess:(BOOL)success {
	
	// Restoring proper data
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	
	NSString *validLogin = [preferences objectForKey:@"settings_valid_login"];
	NSString *validPassword = [preferences objectForKey:@"settings_valid_password"];
	NSString *validServer = [preferences objectForKey:@"settings_valid_server_url"];
	
	[preferences setObject:validLogin
					forKey:@"settings_login"];
	
	[preferences setObject:validPassword
					forKey:@"settings_password"];
	
	[preferences setObject:validServer
					forKey:@"settings_server_url"];
	
	//
	
	[self.presentingViewController dismissViewControllerAnimated:YES
													  completion:nil];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:success]
														 forKey:@"success"];
	
 	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginPopupDismiss"
														object:nil
													  userInfo:userInfo];
}


- (void)enableInterface:(BOOL)enabled {
	
	_loginTextField.enabled = enabled;
	_passwordTextField.enabled = enabled;
	_serverUrlTextField.enabled = enabled;
	
	if (enabled)
		[_activityIndicatorView stopAnimating];
	else
		[_activityIndicatorView startAnimating];
}


#pragma mark - UI callback


- (void)onTextFieldValueChanged {
	_errorText.text = @"";
	[self validateFieldsForConnnectionEvent:FALSE];
}


- (void)onBackButtonClicked {
	[self dismissWithSuccess:FALSE];
}


- (void)onValidateButtonClicked {
	
	// Saving preferences
	
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

	[preferences setObject:_loginTextField.text
					forKey:@"settings_login"];
	
	[preferences setObject:_passwordTextField.text
					forKey:@"settings_password"];
	
	[preferences setObject:_serverUrlTextField.text
					forKey:@"settings_server_url"];
	
	// Test connection
	
	if ([self validateFieldsForConnnectionEvent:TRUE])
		[self testConnection];
}


@end
