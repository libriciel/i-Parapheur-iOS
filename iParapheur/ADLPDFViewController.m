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
#import "ReaderContentView.h"
#import "LGViewHUD.h"
#import "RGDossierDetailViewController.h"
#import "RGDocumentsView.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLAPIOperation.h"
#import "ADLActionViewController.h"
#import "UIColor+CustomColors.h"
#import "ADLResponseCircuit.h"
#import "ADLResponseDossier.h"
#import "ADLResponseAnnotation.h"
#import "ADLResponseSignInfo.h"
#import "DeviceUtils.h"
#import "StringUtils.h"


@interface ADLPDFViewController () <ReaderViewControllerDelegate>

@end

@implementation ADLPDFViewController


#pragma mark - UIViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View loaded : ADLPDFViewController");

	[self deleteEveryBinFile];
	
	// Build UI
	
	self.navigationController.navigationBar.tintColor = [UIColor darkBlueColor];
	self.navigationItem.rightBarButtonItem = nil;
	
	if ([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0) {
		UISplitViewController *uiSplitView = (UISplitViewController *)[UIApplication sharedApplication].delegate.window.rootViewController;
		UIBarButtonItem *backButton = uiSplitView.displayModeButtonItem;
		
		self.navigationItem.leftBarButtonItem = backButton;
		self.navigationItem.leftItemsSupplementBackButton = YES;
		
		@try {
			#pragma clang diagnostic push
			#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[backButton.target performSelector:backButton.action];
			#pragma clang diagnostic pop
		}
		@catch (NSException *e) { }
	}
	
	_restClient = [ADLRestClient sharedManager];
	
	// Notifications register
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dossierSelected:)
												 name:kDossierSelected
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kSelectBureauAppeared
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kDossierActionComplete
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kFilterChanged
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showDocumentWithIndex:)
												 name:kshowDocumentWithIndex
											   object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


- (void)viewDidUnload {
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	else
		return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	// [_readerViewController updateScrollViewContentViews];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
				 sender:(id)sender {
	
	if ([[segue identifier] isEqualToString:@"dossierDetails"]) {
		
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3)
			[((RGDossierDetailViewController*) [segue destinationViewController]) setDossierRef:_dossierRef];
		else
			[((RGDossierDetailViewController*) [segue destinationViewController]) setDossier:_document];
	}
	
	if ([[segue identifier] isEqualToString:@"showDocumentPopover"]) {
		[((RGDocumentsView*)[segue destinationViewController]) setDocuments:_dossier.documents];
		if (_documentsPopover != nil)
			[_documentsPopover dismissPopoverAnimated:NO];
		
		_documentsPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
		[_documentsPopover setDelegate:self];
	}
	
	if ([[segue identifier] isEqualToString:@"showActionPopover"]) {
		if (_actionPopover != nil) {
			[_actionPopover dismissPopoverAnimated:NO];
		}
		
		NSArray* actions;
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
			actions = [ADLAPIHelper actionsForADLResponseDossier:_dossier];
		}
		else {
			actions = [ADLAPIHelper actionsForDossier:self.document];
		}
		
		_actionPopover = [(UIStoryboardPopoverSegue *)segue popoverController];
		((ADLActionViewController*)[_actionPopover contentViewController]).actions = [NSMutableArray arrayWithArray:actions];
		
		// do something usefull there
		if ([_signatureFormat isEqualToString:@"CMS"]) {
			[((ADLActionViewController*)[_actionPopover contentViewController]) setSignatureEnabled:YES];
		}
		else if (_visaEnabled) {
			[((ADLActionViewController*)[_actionPopover contentViewController]) setVisaEnabled:YES];
		}
		
		[_actionPopover setDelegate:self];
		
	}
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - ReaderViewControllerDelegate methods


- (void)dismissReaderViewController:(ReaderViewController *)viewController {
	_readerViewController.delegate = nil;
	[_readerViewController willMoveToParentViewController:nil];
	[_readerViewController.view removeFromSuperview];
	[_readerViewController removeFromParentViewController];
	_readerViewController = nil;
}


#pragma mark - ADLDrawingViewDataSource
#define kActionButtonsWidth 300.0f
#define kActionButtonsHeight 100.0f


-(NSArray*)annotationsForPage:(NSInteger)page {
	
	NSMutableArray *annotsAtPage = [[NSMutableArray alloc] init];
	
	int i = 0; // etapeNumber
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		for (ADLResponseAnnotation *etape in _annotations) {
			NSArray *annotationsAtPageForEtape = [etape.data objectForKey:[NSString stringWithFormat:@"%ld", (long)page]];
			
			if (_circuit && (_circuit.count > 0)) {
				ADLResponseCircuit *circuit = [_circuit objectAtIndex:0];
				
				for (NSDictionary *annot in annotationsAtPageForEtape) {
					NSMutableDictionary *modifiedAnnot = [NSMutableDictionary dictionaryWithDictionary:annot];
					
					if ([[((NSDictionary*)[circuit.etapes objectAtIndex:i]) objectForKey:@"approved"] boolValue]) {
						[modifiedAnnot setObject:[NSNumber numberWithBool:NO]
										  forKey:@"editable"];
					}
					else {
						[modifiedAnnot setObject:[NSNumber numberWithBool:YES]
										  forKey:@"editable"];
					}
					
					[annotsAtPage addObject:[NSDictionary dictionaryWithDictionary:modifiedAnnot]];
				}
			}
			
			i ++;
		}
	}
	else {
		for (NSDictionary *etape in _annotations) {
			NSArray *annotationsAtPageForEtape = [etape objectForKey:[NSString stringWithFormat:@"%ld", (long)page]];
			
			if (self.circuit) {
				for (NSDictionary *annot in annotationsAtPageForEtape) {
					
					NSMutableDictionary *modifiedAnnot = [NSMutableDictionary dictionaryWithDictionary:annot];
					if ([[((NSDictionary*)[self.circuit objectAtIndex:i]) objectForKey:@"approved"] boolValue]) {
						[modifiedAnnot setObject:[NSNumber numberWithBool:NO]
										  forKey:@"editable"];
					}
					else {
						[modifiedAnnot setObject:[NSNumber numberWithBool:YES]
										  forKey:@"editable"];
					}
					[annotsAtPage addObject:[NSDictionary dictionaryWithDictionary:modifiedAnnot]];
				}
			}
			
			i ++;
		}
	}
	
	return annotsAtPage;
}


-(void)updateAnnotation:(ADLAnnotation*)annotation
				forPage:(NSUInteger)page {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		NSDictionary *annotationDictionary = annotation.dict;
		
		[_restClient updateAnnotation:annotationDictionary
							  forPage:(int)page
						   forDossier:[[ADLSingletonState sharedSingletonState] dossierCourant]
							  success:^(NSArray *result) {
								  NSLog(@"updateAnnotation success");
							  }
							  failure:^(NSError *error) {
								  [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
													 withTitle:@"Erreur à la sauvegarde de l'annotation"
														inView:nil];
							  }];
	}
	else {
		NSDictionary *dict = [annotation dict];
		NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithUnsignedInteger:page], @"page",
							 dict, @"annotation",
							 [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
							 , nil];
		
		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:@"updateAnnotation" andArgs:req delegate:self];
	}
}


-(void)removeAnnotation:(ADLAnnotation*)annotation {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		NSDictionary *annotationDictionary = annotation.dict;
		
		[_restClient removeAnnotation:annotationDictionary
						   forDossier:[[ADLSingletonState sharedSingletonState] dossierCourant]
							  success:^(NSArray *result) {
								  NSLog(@"deleteAnnotation success");
							  }
							  failure:^(NSError *error) {
								  [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
													 withTitle:@"Erreur à la suppression de l'annotation"
														inView:nil];
							  }];
	}
	else {
		NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:
							 [annotation uuid], @"uuid",
							 [NSNumber numberWithUnsignedInt:10], @"page",
							 [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
							 , nil];
		
		ADLRequester *requester = [ADLRequester sharedRequester];
		
		[requester request:@"removeAnnotation" andArgs:req delegate:self];
	}
}


-(void)addAnnotation:(ADLAnnotation*)annotation
			 forPage:(NSUInteger)page {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		NSString *login=[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"settings_login"];
		if (login == nil)
			login =	@"bma";
		
		NSDictionary *args = [annotation dict];
		[args setValue:[NSNumber numberWithUnsignedInteger:page] forKey:@"page"];
		[args setValue:[NSDate date] forKey:@"date"];
		[args setValue:@"rect" forKey:@"type"];
		[args setValue:login forKey:@"author"];
		
		__weak typeof(self) weakSelf = self;
		[_restClient addAnnotations:args
						 forDossier:[[ADLSingletonState sharedSingletonState] dossierCourant]
							success:^(NSArray *result) {
								__strong typeof(weakSelf) strongSelf = weakSelf;
								//								if (strongSelf) {
								//									[strongSelf refreshAnnotations:strongSelf.dossierRef];
								//								}
							}
							failure:^(NSError *error) {
								[DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
												   withTitle:@"Erreur à la sauvegarde de l'annotation"
													  inView:nil];
							}];
	}
	else {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[annotation dict]];
		[dict setValue: [NSNumber numberWithUnsignedInteger:page] forKey:@"page"];
		NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSArray arrayWithObjects:dict, nil], @"annotations",
							  [[ADLSingletonState sharedSingletonState] dossierCourant], @"dossier"
							  , nil];
		
		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:@"addAnnotation" andArgs:args delegate:self];
	}
}


#pragma mark - LGViewHUDDelegate


-(void)shallDismissHUD:(LGViewHUD*)hud {
	HIDE_HUD
}


#pragma mark - ADLParapheurWallDelegateProtocol


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
	
	[self requestSignInfoForDossier:dossier];
}


/**
 * Responses for API v2 requests.
 */
-(void)didEndWithRequestAnswer:(NSDictionary*)answer {
	NSString *s = [answer objectForKey:@"_req"];
	HIDE_HUD
	
	if ([s isEqual:GETDOSSIER_API]) {
		_document = [answer copy];
		[self displayDocumentAt: 0];
		
		self.navigationController.navigationBar.topItem.title = [_document objectForKey:@"titre"];
		
		NSArray *buttons;
		
		if ([[_document objectForKey:@"documents"] count] > 1)
			buttons = [[NSArray alloc] initWithObjects:_actionButton, _documentsButton, _detailsButton, nil];
		else
			buttons = [[NSArray alloc] initWithObjects:_actionButton, _detailsButton, nil];
		
		self.navigationItem.rightBarButtonItems = buttons;
		
		NSString *documentPrincipal = [[[_document objectForKey:@"documents"] objectAtIndex:0] objectForKey:@"downloadUrl"];
		[[ADLSingletonState sharedSingletonState] setCurrentPrincipalDocPath:documentPrincipal];
		NSLog(@"%@", [_document objectForKey:@"actions"]);
		
		if ([[[_document objectForKey:@"actions"] objectForKey:@"sign"] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
			if ([[_document objectForKey:@"actionDemandee"] isEqualToString:@"SIGNATURE"]) {
				NSDictionary *signInfoArgs = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:_dossierRef], @"dossiers", nil];
				ADLRequester *requester = [ADLRequester sharedRequester];
				[requester request:@"getSignInfo" andArgs:signInfoArgs delegate:self];
			}
			else {
				_visaEnabled = YES;
				_signatureFormat = nil;
			}
		}
		
		SHOW_HUD
	}
	else if ([s isEqualToString:@"getSignInfo"]) {
		_signatureFormat = [[[answer objectForKey:_dossierRef] objectForKey:@"format"] copy];
	}
	else if ([s isEqualToString:GETANNOTATIONS_API]) {
		NSArray *annotations = [[answer objectForKey:@"annotations"] copy];
		
		_annotations = annotations;
		
//		for (NSNumber *contentViewIdx in [_readerViewController contentViews])
//			[[[[_readerViewController contentViews] objectForKey:contentViewIdx] contentPage] refreshAnnotations];
	}
	else if ([s isEqualToString:@"addAnnotation"]) {
		API_GETANNOTATIONS(_dossierRef);
	}
	else if ([s isEqual:GETCIRCUIT_API]) {
		self.circuit = [answer objectForKey:@"circuit"];
		API_GETANNOTATIONS(_dossierRef);
	}
}


-(void)didEndWithUnReachableNetwork {
	HIDE_HUD
}


-(void)didEndWithUnAuthorizedAccess {
	HIDE_HUD
}


#pragma mark - NotificationCenter selectors


-(void)dossierSelected:(NSNotification*) notification {
	NSString *dossierRef = [notification object];
	
	_dossierRef = dossierRef;
	
	SHOW_HUD
	
	__weak typeof(self) weakSelf = self;
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[_restClient getDossier:[[ADLSingletonState sharedSingletonState] bureauCourant]
						dossier:_dossierRef
						success:^(ADLResponseDossier *result) {
							__strong typeof(weakSelf) strongSelf = weakSelf;
							if (strongSelf) {
								HIDE_HUD
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
										HIDE_HUD
										strongSelf.circuit = [NSMutableArray arrayWithObject:circuit];
										//[strongSelf refreshAnnotations:dossierRef];
									}
								}
								failure:^(NSError *error) {
									NSLog(@"getCircuit fail : %@", error.localizedDescription);
								}];
	}
	else {
		API_GETDOSSIER(_dossierRef, [[ADLSingletonState sharedSingletonState] bureauCourant]);
		API_GETCIRCUIT(_dossierRef);
	}
	
	//[[self navigationController] popToRootViewControllerAnimated:YES];
}


-(void)showDocumentWithIndex:(NSNotification*) notification {
	
	NSNumber* docIndex = [notification object];
	[self displayDocumentAt:[docIndex integerValue]];
	[_documentsPopover dismissPopoverAnimated:YES];
	_documentsPopover = nil;
}


-(void)clearDetail: (NSNotification*) notification {
	[self dismissReaderViewController:_readerViewController];
	
	// Hide title
	
	self.navigationController.navigationBar.topItem.title = nil;
	
	// Hide Buttons
	
	NSArray *buttons = [[NSArray alloc] initWithObjects:nil];
	self.navigationItem.rightBarButtonItems = buttons;
	
	// Hide popovers
	
	if (_documentsPopover != nil)
		[_documentsPopover dismissPopoverAnimated:NO];

	if (_actionPopover != nil)
		[_actionPopover dismissPopoverAnimated:NO];
}


#pragma mark - Split view


-(void)splitViewController:(UISplitViewController *)splitController
	willHideViewController:(UIViewController *)viewController
		 withBarButtonItem:(UIBarButtonItem *)barButtonItem
	  forPopoverController:(UIPopoverController *)popoverController {
	
	barButtonItem.title = @"Dossiers";
	barButtonItem.tintColor = [UIColor darkBlueColor];
	
//	[self.navigationItem setLeftBarButtonItem:barButtonItem
//									 animated:YES];
//	self.masterPopoverController = popoverController;
}


-(void)splitViewController:(UISplitViewController *)splitController
	willShowViewController:(UIViewController *)viewController
 invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	
	// Called when the view is shown again in the split view, invalidating the button and popover controller.
//	[self.navigationItem setLeftBarButtonItem:nil
//									 animated:YES];
	
//	self.masterPopoverController = nil;
}


#pragma mark - Private methods


-(void)deleteEveryBinFile {
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//here everything you want to perform in background
		
		// The preferred way to get the apps documents directory
		
		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *docDirectory = [documentsPaths objectAtIndex:0];
		
		// Grab all the files in the documents dir
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:docDirectory error:nil];
		
		// Filter the array for only bin files
		
		NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.bin'"];
		NSArray *binFiles = [allFiles filteredArrayUsingPredicate:fltr];
		
		// Use fast enumeration to iterate the array and delete the files
		
		for (NSString *binFile in binFiles) {
			NSError *error = nil;
			[fileManager removeItemAtPath:[docDirectory stringByAppendingPathComponent:binFile] error:&error];
		}
	});
}


-(NSString *)getFilePathWithDossierRef:(NSString *)dossierRef {
	
	// The preferred way to get the apps documents directory
	
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = [documentsPaths objectAtIndex:0];
	
	// Grab all the files in the documents dir
	
	NSString *fileName = [NSString stringWithFormat:@"%@.bin", _dossierRef];
	NSString *filePath = [docDirectory stringByAppendingPathComponent:fileName];
	
	return filePath;
}


-(void)requestAnnotations {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getAnnotations:_dossierRef
							success:^(NSArray *annotations) {
								__strong typeof(weakSelf) strongSelf = weakSelf;
								if (strongSelf) {
									strongSelf.annotations = annotations;
									
									//								for (NSNumber *contentViewIdx in [strongSelf.readerViewController contentViews])
									//									[[[[strongSelf.readerViewController contentViews] objectForKey:contentViewIdx] contentPage] requestAnnotations];
								}
							} failure:^(NSError *error) {
								NSLog(@"getAnnotations error");
							}];
	}
	else {
		ADLRequester *requester = [ADLRequester sharedRequester];
		NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:_dossierRef, @"dossier", nil];
		[requester request:GETANNOTATIONS_API
				   andArgs:args
				  delegate:self];
	}
}


-(void)requestSignInfoForDossier:(ADLResponseDossier*)dossier {
	
	if ([dossier.actions containsObject:@"SIGNATURE"]) {
		if ([dossier.actionDemandee isEqualToString:@"SIGNATURE"]) {
			if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
				SHOW_HUD
				__weak typeof(self) weakSelf = self;
				[_restClient getSignInfoForDossier:_dossierRef
										 andBureau:[[ADLSingletonState sharedSingletonState] bureauCourant]
										   success:^(ADLResponseSignInfo *signInfo) {
											   __strong typeof(weakSelf) strongSelf = weakSelf;
											   if (strongSelf) {
												   strongSelf.signatureFormat = [signInfo.signatureInformations objectForKey:@"format"];
												   HIDE_HUD
											   }
										   }
										   failure:^(NSError *error) {
											   HIDE_HUD
											   NSLog(@"getSignInfo %@", error.localizedDescription);
										   }];
			}
			else {
				SHOW_HUD
				NSDictionary *signInfoArgs = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:_dossierRef], @"dossiers", nil];
				ADLRequester *requester = [ADLRequester sharedRequester];
				[requester request:@"getSignInfo" andArgs:signInfoArgs delegate:self];
			}
		}
		else {
			_visaEnabled = YES;
			_signatureFormat = nil;
		}
	}
}


-(void)loadPdfAt:(NSString *)filePath {
	_readerDocument = [ReaderDocument withDocumentFilePath:filePath password:nil];
	
	if (_readerDocument != nil) // Must have a valid ReaderDocument object in order to proceed with things
	{
		// Deleting previous child controller
		
		_readerViewController.delegate = nil;
		[_readerViewController willMoveToParentViewController:nil];
		[_readerViewController.view removeFromSuperview];
		[_readerViewController removeFromParentViewController];
		_readerViewController = nil;
		
		// Creating new child controller
		
		_readerViewController = [[ReaderViewController alloc] initWithReaderDocument:_readerDocument];
		
		_readerViewController.delegate = self; // Set the ReaderViewController delegate to self
		
		_readerViewController.view.frame = CGRectMake(0, 0, [self view].frame.size.width, [self view].frame.size.height);
		
		[_readerViewController.view setAutoresizingMask:( UIViewAutoresizingFlexibleWidth |
														 UIViewAutoresizingFlexibleHeight )];
		[[self view] setAutoresizesSubviews:YES];
		[[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		[self addChildViewController:_readerViewController];
		[[self view] addSubview:_readerViewController.view];
	}
	else // Log an error so that we know that something went wrong
	{
		NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, filePath, nil);
	}
}


-(void)displayDocumentAt:(NSInteger)index {
	
	_isDocumentPrincipal = (index == 0);
	
	// File cache
	
	NSString *filePath = [self getFilePathWithDossierRef:_dossierRef];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		
		NSLog(@"PDF : Cached data");

		[self loadPdfAt:filePath];
		[self requestAnnotations];
		
		return;
	}
	
	// Downloading files
	
	NSLog(@"PDF : Download data");
	
	SHOW_HUD
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
	
	HIDE_HUD
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//here everything you want to perform in background
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSFileHandle *file;
		
		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		
		NSString *docPath = [documentsPaths objectAtIndex:0];
		NSString *filePath = [NSString stringWithFormat:@"%@/%@.bin", docPath, _dossierRef];
		[fileManager createFileAtPath:filePath
							 contents:nil
						   attributes:nil];
		
		file = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[file writeData:[document documentData]];

		
		dispatch_async(dispatch_get_main_queue(), ^{
			//call back to main queue to update user interface
			[self loadPdfAt:filePath];
			[self requestAnnotations];
		});
	});
}


@end
