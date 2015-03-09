//
//  RGSplashscreenViewController.m
//  iParapheur
//
//

#import "RGSplashscreenViewController.h"
#import "AJNotificationView.h"
#import "ADLRestClient.h"
#import "UIColor+CustomColors.h"


@interface RGSplashscreenViewController ()

@end

@implementation RGSplashscreenViewController


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
	[_activityIndicatorView startAnimating];
	
	[restClient getApiLevel:^(NSNumber *versionNumber) {
						[_activityIndicatorView stopAnimating];
						[self dismissWithSuccess:TRUE];
					}
					failure:^(NSError *error) {
						[_activityIndicatorView stopAnimating];
//						UIViewController *rootController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
//						[AJNotificationView showNoticeInView:[rootController view]
//														type:AJNotificationTypeRed
//													   title:[error localizedDescription]
//											 linedBackground:AJLinedBackgroundTypeStatic
//												   hideAfter:2.5f];
						
						
					 }];
}


- (void)dismissWithSuccess:(BOOL)success {
	
	[self.presentingViewController dismissViewControllerAnimated:YES
													  completion:nil];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:success]
														 forKey:@"success"];
	
 	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginPopupDismiss"
														object:nil
													  userInfo:userInfo];
}


#pragma mark - UI callback


- (void)onTextFieldValueChanged {
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
