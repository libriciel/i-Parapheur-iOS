//
//  RGSplashscreenViewController.m
//  iParapheur
//
//  Created by Adrien Bricchi on 05/03/2015.
//
//

#import "RGSplashscreenViewController.h"
#import "AJNotificationView.h"
#import "ADLRestClient.h"


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
	
	// TODO Adrien : load registered values
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


#pragma mark - Private methods


- (BOOL)validateFields {
	
	BOOL loginTextFieldValid = (_loginTextField.text.length != 0);
	BOOL passwordTextFieldValid = (_passwordTextField.text.length != 0);
	BOOL serverTextFieldValid = (_serverUrlTextField.text.length != 0);
	
	// TODO Adrien : add special character restrictions tests, and url validation field test
	
	[self setBorderOnTextField:_loginTextField
					 withAlert:!loginTextFieldValid];

	[self setBorderOnTextField:_passwordTextField
					 withAlert:!passwordTextFieldValid];
	
	[self setBorderOnTextField:_serverUrlTextField
					 withAlert:!serverTextFieldValid];

	
	return (loginTextFieldValid && passwordTextFieldValid && serverTextFieldValid);
}

- (void)setBorderOnTextField:(UITextField *)textField
				   withAlert:(BOOL)alert {
	
	if (alert) {
		
		textField.layer.cornerRadius=6.0f;
		textField.layer.masksToBounds=YES;
		textField.layer.borderWidth= 1.0f;
		textField.layer.borderColor=[[UIColor colorWithRed:255.0/255.0
													 green:150.0/255.0
													  blue:0.0/255.0
													 alpha:1] CGColor];
		
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
	
	if ([self validateFields])
		[self testConnection];
}


@end
