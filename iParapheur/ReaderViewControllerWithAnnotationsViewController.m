//
//  ReaderViewControllerWithAnnotationsViewController.m
//  iParapheur
//
//
//

#import "ReaderViewControllerWithAnnotationsViewController.h"

@interface ReaderViewControllerWithAnnotationsViewController ()

@end


@implementation ReaderViewControllerWithAnnotationsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	NSLog(@"View loaded : ReaderViewControllerWithAnnotationsViewController");

	[super getMainToolBar].hidden=TRUE;
}


- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {

	// Retrieve ContentPage
	
	NSNumber *key = [NSNumber numberWithInteger:[self getCurrentPage]]; // Page number key
	ReaderContentView *targetView = [[self getContentViews] objectForKey:key]; // View
	ADLDrawingView *contentPage = (ADLDrawingView *)[targetView getTheContentPage];

	// Send event
	
	[contentPage handleDoubleTap:recognizer];
}


@end
