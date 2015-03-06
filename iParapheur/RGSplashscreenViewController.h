//
//  RGSplashscreenViewController.h
//  iParapheur
//
//  Created by Adrien Bricchi on 05/03/2015.
//
//

#import <UIKit/UIKit.h>

@interface RGSplashscreenViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *serverUrlTextField;
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
