//
//  ReaderViewControllerWithAnnotationsViewController.h
//  iParapheur
//
//  This is an overriden VFR's ReaderViewController.
//	Useful to set the minimum of modifications possible in the original one,
//	(only accessors are added).
//
//	That will ease future updates of the VFR lib :
//	Just look for "#pragma mark - Adullact fork" tags,
//	and everything else can be modified.
//
//

#import "ReaderViewController.h"
#import "ADLDrawingView.h"
#import "ReaderContentView.h"


@interface ReaderViewControllerWithAnnotationsViewController : ReaderViewController

@property (nonatomic, strong) ReaderContentPage *contentPage;

@end
