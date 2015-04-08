//
//	ReaderDemoController.m
//	Reader v2.8.6
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2015 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ADLPDFViewController.h"
#import "ReaderViewController.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLNotifications.h"

@interface ADLPDFViewController () <ReaderViewControllerDelegate>

@end

@implementation ADLPDFViewController

#pragma mark - UIViewController methods


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor clearColor]; // Transparent
	
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	
	NSString *name = [infoDictionary objectForKey:@"CFBundleName"];
	
	NSString *version = [infoDictionary objectForKey:@"CFBundleVersion"];
	
	self.title = [[NSString alloc] initWithFormat:@"%@ v%@", name, version];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dossierSelected:)
												 name:kDossierSelected
											   object:nil];

	_restClient = [ADLRestClient sharedManager];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) // See README
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	else
		return YES;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
	
	[super didReceiveMemoryWarning];
}

#pragma mark - ReaderViewControllerDelegate methods

- (void)dismissReaderViewController:(ReaderViewController *)viewController
{
#if (DEMO_VIEW_CONTROLLER_PUSH == TRUE)
	
	[self.navigationController popViewControllerAnimated:YES];
	
#else // dismiss the modal view controller
	
	[self dismissViewControllerAnimated:YES completion:NULL];
	
#endif // DEMO_VIEW_CONTROLLER_PUSH
	
}


-(void)dossierSelected: (NSNotification*) notification {
	NSString *dossierRef = [notification object];
	_dossierRef = dossierRef;
	
	for(UIView *subview in [self.view subviews]) {
		[subview removeFromSuperview];
	}
	
	//SHOW_HUD
	
	__weak typeof(self) weakSelf = self;
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[_restClient getDossier:[[ADLSingletonState sharedSingletonState] bureauCourant]
						dossier:_dossierRef
						success:^(ADLResponseDossier *result) {
							__strong typeof(weakSelf) strongSelf = weakSelf;
							if (strongSelf) {
								//HIDE_HUD
								[strongSelf getDossierDidEndWithRequestAnswer:result];
							}
						}
						failure:^(NSError *error) {
							NSLog(@"getBureau fail : %@", error.localizedDescription);
						}];
		
		[_restClient getCircuit:_dossierRef
						success:^(ADLResponseCircuit *circuit) {
							__strong typeof(weakSelf) strongSelf = weakSelf;
							if (strongSelf) {
								//HIDE_HUD
								strongSelf.circuit = [NSMutableArray arrayWithObject:circuit];
								//[strongSelf refreshAnnotations:dossierRef];
							}
						}
						failure:^(NSError *error) {
							NSLog(@"getCircuit fail : %@", error.localizedDescription);
						}];
	}
	else {
		// API_GETDOSSIER(_dossierRef, [[ADLSingletonState sharedSingletonState] bureauCourant]);
		// API_GETCIRCUIT(_dossierRef);
	}
	
	//[[self navigationController] popToRootViewControllerAnimated:YES];
}


/**
 * GetDossier response on API v3.
 */
-(void)getDossierDidEndWithRequestAnswer:(ADLResponseDossier *)dossier {
	_dossier = dossier ;
	
	// Determine the first pdf file to display
	
	for (NSDictionary *dossierDictionnary in dossier.documents) {
		if ([dossierDictionnary valueForKey:@"visuelPdf"]) {
			_document = dossierDictionnary;
			break;
		}
	}
	
	//
	
	[self displayDocumentAt: 0];
	self.navigationController.navigationBar.topItem.title = dossier.title;
	
	// Refresh buttons
	
	NSArray *buttons;
	
	if (dossier.documents.count > 1)
		buttons = [[NSArray alloc] initWithObjects:_actionButton, _documentsButton, _detailsButton, nil];
	else
		buttons = [[NSArray alloc] initWithObjects:_actionButton, _detailsButton, nil];
	
	self.navigationItem.rightBarButtonItems = buttons;
	
	//[self refreshSignInfoForDossier:dossier];
}


-(void)displayDocumentAt:(NSInteger)index {
	
	//SHOW_HUD
	
	_isDocumentPrincipal = (index == 0);
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	if (([[ADLRestClient getRestApiVersion] intValue ] == 3) && _dossier.documents) {
		_document = _dossier.documents[index];
		bool isPdf = [[_document objectForKey:@"visuelPdf"] boolValue];
		NSString *documentId = [_document objectForKey:@"id"];
		[requester downloadDocumentAt:[_restClient getDownloadUrl:documentId
														   forPdf:isPdf]
							 delegate:self];
	}
	else if (_document) {
		NSDictionary *document = [[_document objectForKey:@"documents" ] objectAtIndex:index];
		
		// Si le document n'a pas de visuelPdf on suppose que le document est en PDF
		if ([document objectForKey:@"visuelPdfUrl"] != nil) {
			[requester downloadDocumentAt:[document objectForKey:@"visuelPdfUrl"]
								 delegate:self];
		}
		else if ([document objectForKey:@"downloadUrl"] != nil) {
			[requester downloadDocumentAt:[document objectForKey:@"downloadUrl"]
								 delegate:self];
		}
	}
}

-(void)didEndWithDocument:(ADLDocument*)document {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSFileHandle *file;
	
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	NSString *docPath = [documentsPaths objectAtIndex:0];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@.bin", docPath, @"myfile"];
	[fileManager createFileAtPath:filePath
						 contents:nil
					   attributes:nil];
	
	file = [NSFileHandle fileHandleForWritingAtPath:filePath];
	[file writeData:[document documentData]];
	
	[self didEndWithDocumentAtPath:filePath];
}


-(void)didEndWithDocumentAtPath:(NSString*)filePath {
	
	NSLog(@"Adrien %@", filePath);
	
	// Adrien Releasing old ReaderViewController
	
	if (_readerViewController) {
		_readerDocument = nil;
		_readerViewController.delegate = nil;
		NSLog(@"Adrien - Controller retain count : %ld", CFGetRetainCount((__bridge CFTypeRef)_readerViewController));
		[_readerViewController willMoveToParentViewController:nil];
		NSLog(@"Adrien - Controller retain count : %ld", CFGetRetainCount((__bridge CFTypeRef)_readerViewController));
		_readerViewController = nil;
		
		for (CALayer* layer in [self.view.layer sublayers])
		{
			[layer removeAllAnimations];
		}
	}
	
	for(UIView *subview in [self.view subviews]) {
		NSLog(@"Adrien - View retain count : %ld", CFGetRetainCount((__bridge CFTypeRef)subview));
		[subview removeFromSuperview];
		NSLog(@"Adrien - View retain count : %ld", CFGetRetainCount((__bridge CFTypeRef)subview));
	}
	
	// new ReaderViewController
	
	_readerDocument = [ReaderDocument withDocumentFilePath:filePath password:nil];
	ReaderViewController *readerViewController = [[ReaderViewController alloc] initWithReaderDocument:_readerDocument];
	readerViewController.delegate = self;
	
	readerViewController.view.frame = CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height);
	
	[readerViewController.view setAutoresizingMask:( UIViewAutoresizingFlexibleWidth |
													 UIViewAutoresizingFlexibleHeight )];
	
	[[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[[self view] addSubview:readerViewController.view];
	
	HIDE_HUD
	
	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:_dossierRef, @"dossier", nil];
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		//[self refreshAnnotations:_dossierRef];
	}
	else {
		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:GETANNOTATIONS_API
				   andArgs:args
				  delegate:self];
	}
}


@end
