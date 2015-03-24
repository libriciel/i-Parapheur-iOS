//
//  RGSplashscreenViewController.m
//  iParapheur
//
//

#import "RGLoginViewController.h"
#import "AJNotificationView.h"
#import "ADLRestClientApi3.h"
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
	
	// TODO Adrien : add special character restrictions tests, and url format validation field test ?
	
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
		textField.layer.borderColor=[[UIColor darkOrangeColor] CGColor];
		textField.backgroundColor=[[UIColor darkOrangeColor] colorWithAlphaComponent:0.1];
	}
	else {
		textField.layer.borderColor = [[UIColor clearColor]CGColor];
		textField.backgroundColor = [UIColor clearColor];
	}
}


- (void)testConnection {

	if (_restClient)
		[_restClient cancelAllOperations];
	
	_restClient = [[ADLRestClientApi3 alloc] initWithLogin:_loginTextField.text
												  password:_passwordTextField.text
													   url:[self cleanupServerName:_serverUrlTextField.text]];
	
	[self enableInterface:FALSE];

	[_restClient getApiLevel:^(NSNumber *versionNumber) {
		
						[self enableInterface:TRUE];
						[self dismissWithSuccess:TRUE];
					 }
					 failure:^(NSError *error) {
						 
						[self enableInterface:TRUE];
						
						if ( ((kCFURLErrorCannotLoadFromNetwork <= error.code) && (error.code <= kCFURLErrorSecureConnectionFailed)) || (error.code == kCFURLErrorCancelled) ) {
							[self setBorderOnTextField:_serverUrlTextField withAlert:TRUE];
							_errorTextField.text = @"Le serveur n'est pas valide";
						}
						else if (error.code == kCFURLErrorUserAuthenticationRequired) {
							[self setBorderOnTextField:_loginTextField withAlert:TRUE];
							[self setBorderOnTextField:_passwordTextField withAlert:TRUE];
							_errorTextField.text = @"Échec d'authentification";
						}
						else if ((error.code == kCFURLErrorCannotFindHost) || (error.code == kCFURLErrorBadServerResponse)) {
							[self setBorderOnTextField:_serverUrlTextField withAlert:TRUE];
							_errorTextField.text = @"Le serveur est introuvable";
						}
						else if (error.code == kCFURLErrorTimedOut) {
							[self setBorderOnTextField:_serverUrlTextField withAlert:TRUE];
							_errorTextField.text = @"Le serveur ne répond pas dans le délai imparti";
						}
						else {
							_errorTextField.text = [NSString stringWithFormat:@"La connexion au serveur a échoué (code %ld)", (long)error.code];
						}
					 }];
}


- (void)dismissWithSuccess:(BOOL)success {
	
	if (_restClient)
	[_restClient cancelAllOperations];
	
	// Saving proper data
	
	if (success) {
		NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
		
		[preferences setObject:_loginTextField.text
						forKey:@"settings_login"];
		
		[preferences setObject:_passwordTextField.text
						forKey:@"settings_password"];
		
		[preferences setObject:[self cleanupServerName:_serverUrlTextField.text]
						forKey:@"settings_server_url"];
	}
	
	// Reset singleton values
	
	[[ADLRestClient sharedManager] reset];
	
	//
	
	[self.presentingViewController dismissViewControllerAnimated:YES
													  completion:nil];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:success]
														 forKey:@"success"];
	
 	[[NSNotificationCenter defaultCenter] postNotificationName:@"loginPopupDismiss"
														object:nil
													  userInfo:userInfo];
}


- (NSString *)cleanupServerName:(NSString *)url {
	
	if ([url hasPrefix:@"https://m."])
		url = [url substringFromIndex:10];

	if ([url hasPrefix:@"http://m."])
		url = [url substringFromIndex:9];
	
	if ([url hasPrefix:@"https://"])
		url = [url substringFromIndex:8];
	
	if ([url hasPrefix:@"http://"])
		url = [url substringFromIndex:7];
	
	if ([url hasPrefix:@"m."])
		url = [url substringFromIndex:2];
	
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
