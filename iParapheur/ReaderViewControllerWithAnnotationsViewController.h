//
//  ReaderViewControllerWithAnnotationsViewController.h
//  iParapheur
//
//  This is an overriden VFR's ReaderWiewController.
//	Useful to set the minimum of modifications possible in the original one,
//	(only accessors are added).
//	That will ease future updates of the VFR lib.
//
//

#import "ReaderViewController.h"
#import "ADLDrawingView.h"
#import "ReaderContentView.h"


@interface ReaderViewControllerWithAnnotationsViewController : ReaderViewController

@property (nonatomic, strong) ReaderContentPage *contentPage;

@end
