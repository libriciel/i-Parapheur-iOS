//
//  ReaderViewControllerWithAnnotationsViewController.m
//  iParapheur
//
//  Created by Adrien Bricchi on 10/04/2015.
//
//

#import "ReaderViewControllerWithAnnotationsViewController.h"

@interface ReaderViewControllerWithAnnotationsViewController ()

@end


@implementation ReaderViewControllerWithAnnotationsViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	NSLog(@"View loaded : ReaderViewControllerWithAnnotationsViewController");

	[[super getMainToolBar] removeFromSuperview];
	
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer{
	NSLog(@"Adrien Double tap");
}

@end
