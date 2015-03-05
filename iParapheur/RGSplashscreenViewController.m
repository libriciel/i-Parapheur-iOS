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
	
	[_validButton addTarget:self
					 action:@selector(validateButtonClicked)
		   forControlEvents:UIControlEventTouchUpInside];
	
	NSLog(@"View Loaded : SplashScreenViewController");
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
	
	return (loginTextFieldValid && passwordTextFieldValid && serverTextFieldValid);
}

- (void)testConnection {

	ADLRestClient *restClient = [[ADLRestClient alloc] init];
	[_activityIndicatorView startAnimating];
	
	[restClient getApiLevel:^(NSNumber *versionNumber) {
						NSLog(@"Adrien success ==");
						[_activityIndicatorView stopAnimating];
						[self shouldQuit];
					}
					failure:^(NSError *error) {
						NSLog(@"Adrien error ==");
						[_activityIndicatorView stopAnimating];
						UIViewController *rootController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
						[AJNotificationView showNoticeInView:[rootController view]
														type:AJNotificationTypeRed
													   title:[error localizedDescription]
											 linedBackground:AJLinedBackgroundTypeStatic
												   hideAfter:2.5f];
					 }];
	
}


- (void)shouldQuit {
	NSLog(@"Adrien - shouldQuit");
}


#pragma mark - UI Callback


-(void)validateButtonClicked {
	NSLog(@"Adrien CLICK ! %@ - %@ - %@", _loginTextField.text, _passwordTextField.text, _serverUrlTextField.text);
	
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


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end
