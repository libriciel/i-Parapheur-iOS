//
// Created by Adrien Bricchi on 02/11/2015.
//

#import "SettingsTableViewController.h"


@implementation SettingsTableViewController {
	IBOutlet UIBarButtonItem *backButton;
}

- (void)viewDidLoad {
	NSLog(@"View Loaded : SettingsTableViewController");

	backButton.target = self;
	backButton.action = @selector(onBackButtonClicked:);
}


#pragma mark - Buttons callbacks

- (void)onBackButtonClicked:(id)sender {

	[self.presentingViewController dismissViewControllerAnimated:YES
	                                                  completion:nil];
}


@end