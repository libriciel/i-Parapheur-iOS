//
//  RGSplashscreenViewController.h
//  iParapheur
//
//

#import <UIKit/UIKit.h>

@interface RGLoginViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *serverUrlTextField;
@property (strong, nonatomic) IBOutlet UITextField *loginTextField;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UITextView *errorTextField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
