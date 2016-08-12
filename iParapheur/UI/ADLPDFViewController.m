/*
 * Copyright 2012-2016, Adullact-Projet.
 * Contributors : SKROBS (2012)
 *
 * contact@adullact-projet.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */
#import "ADLPDFViewController.h"
#import "ReaderContentView.h"
#import "ReaderContentPage.h"
#import "RGDossierDetailViewController.h"
#import "RGDocumentsView.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLActionViewController.h"
#import "UIColor+CustomColors.h"
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
		UISplitViewController *uiSplitView = (UISplitViewController *) [UIApplication sharedApplication].delegate.window.rootViewController;
		UIBarButtonItem *backButton = uiSplitView.displayModeButtonItem;

		self.navigationItem.leftBarButtonItem = backButton;
		self.navigationItem.leftItemsSupplementBackButton = YES;

		@try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[backButton.target performSelector:backButton.action];
#pragma clang diagnostic pop
		}
		@catch (NSException *e) {}
	}

	_restClient = [ADLRestClient sharedManager];
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

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

	//

	[self.navigationController setNavigationBarHidden:NO
	                                         animated:animated];
}


- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
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

	if ([segue.identifier isEqualToString:@"dossierDetails"]) {

		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3)
			((RGDossierDetailViewController *) segue.destinationViewController).dossierRef = _dossierRef;
		else
			((RGDossierDetailViewController *) segue.destinationViewController).dossier = _document;
	}

	if ([segue.identifier isEqualToString:@"showDocumentPopover"]) {
		((RGDocumentsView *) segue.destinationViewController).documents = _dossier.unwrappedDocuments;
		if (_documentsPopover != nil)
			[_documentsPopover dismissPopoverAnimated:NO];

		_documentsPopover = ((UIStoryboardPopoverSegue *) segue).popoverController;
		_documentsPopover.delegate = self;
	}

	if ([segue.identifier isEqualToString:@"showActionPopover"]) {
		if (_actionPopover != nil) {
			[_actionPopover dismissPopoverAnimated:NO];
		}

		NSArray *actions;
		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
			actions = [ADLAPIHelper actionsForADLResponseDossier:_dossier];
		}
		else {
			actions = [ADLAPIHelper actionsForDossier:_document];
		}

		_actionPopover = ((UIStoryboardPopoverSegue *) segue).popoverController;
		((ADLActionViewController *) _actionPopover.contentViewController).actions = actions.mutableCopy;

		// do something usefull there
		if ([_signatureFormat isEqualToString:@"CMS"]) {
			((ADLActionViewController *) _actionPopover.contentViewController).signatureEnabled = YES;
		}
		else if (_visaEnabled) {
			((ADLActionViewController *) _actionPopover.contentViewController).visaEnabled = YES;
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
	_readerViewController.dataSource = nil;
	[_readerViewController willMoveToParentViewController:nil];
	[_readerViewController.view removeFromSuperview];
	[_readerViewController removeFromParentViewController];
	_readerViewController = nil;
}


#pragma mark - ADLDrawingViewDataSource
#define kActionButtonsWidth 300.0f
#define kActionButtonsHeight 100.0f


- (NSArray *)annotationsForPage:(NSInteger)page {

	// Get current step

	int currentStep = 0;

	if (_circuit && (_circuit.count > 0)) {
		for (NSUInteger i = 0; i < _circuit.count; i++) {

			NSArray *steps = ((ADLResponseCircuit *) _circuit[i]).etapes;
			for (NSUInteger j = 0; j < steps.count; j++) {

				NSDictionary *stepDict = ((NSDictionary *) steps[j]);
				if ([stepDict[@"approved"] boolValue]) {
					// If this step was approved, the current step might be the next one
					currentStep = j + 1;
				}
			}
		}
	}

	// Updating annotations

	for (Annotation *annotation in _annotations) {
		bool isEditable = (annotation.unwrappedStep.intValue >= currentStep);
		[annotation setUnwrappedEditable:(isEditable ? @(1) : @(0))];
	}

	// Filtering annotations

	NSArray *result = [_annotations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {

		bool isPage = ((Annotation *) object).unwrappedPage.intValue == page;
		bool isDoc = [((Annotation *) object).unwrappedDocumentId isEqualToString:_document.unwrappedId];
		bool isApi3 = [((Annotation *) object).unwrappedDocumentId isEqualToString:@"*"];

		return isPage && (isDoc || isApi3);
	}]];

	return result;
}


- (void)updateAnnotation:(Annotation *)annotation {

	[_restClient updateAnnotation:annotation
	                   forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
	                      success:^(NSArray *result) {
		                      NSLog(@"updateAnnotation success");
	                      }
	                      failure:^(NSError *error) {
		                      [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
		                                         withTitle:@"Erreur à la sauvegarde de l'annotation"];
	                      }];
}


- (void)removeAnnotation:(Annotation *)annotation {

	[_restClient removeAnnotation:annotation
	                   forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
	                      success:^(NSArray *result) {
		                      NSLog(@"deleteAnnotation success");
	                      }
	                      failure:^(NSError *error) {
		                      [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
		                                         withTitle:@"Erreur à la suppression de l'annotation"];
	                      }];
}


- (void)addAnnotation:(Annotation *)annotation {

	NSString *login = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation][@"settings_login"];
	[annotation setUnwrappedAuthor:login];
	[annotation setUnwrappedDocumentId:_document.unwrappedId];

	__weak typeof(self) weakSelf = self;
	[_restClient addAnnotation:annotation
	                forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
	                   success:^(NSArray *result) {
		                   __strong typeof(weakSelf) strongSelf = weakSelf;
		                   if (strongSelf) {
			                   [strongSelf requestAnnotations];
		                   }
	                   }
	                   failure:^(NSError *error) {
		                   [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
		                                      withTitle:@"Erreur à la sauvegarde de l'annotation"];
	                   }];
}


#pragma mark - LGViewHUDDelegate


- (void)shallDismissHUD:(LGViewHUD *)hud {

	HIDE_HUD
}


#pragma mark - ADLParapheurWallDelegateProtocol


- (void)getDossierDidEndWithRequestAnswer:(Dossier *)dossier {

	_dossier = dossier;

	// Determine the first pdf file to display

	for (Document *document in [dossier unwrappedDocuments]) {
		if (document.isVisuelPdf) {
			_document = document;
			break;
		}
	}

	//

	[self displayDocumentAt:0];
	self.navigationController.navigationBar.topItem.title = dossier.unwrappedTitle;

	// Refresh buttons

	NSArray *buttons;

	if ([dossier unwrappedDocuments].count > 1)
		buttons = @[_actionButton, _documentsButton, _detailsButton];
	else
		buttons = @[_actionButton, _detailsButton];

	self.navigationItem.rightBarButtonItems = buttons;

	[self requestSignInfoForDossier:dossier];
}


/**
* Responses for API v2 requests.
*/
- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSString *s = answer[@"_req"];
	HIDE_HUD

	if ([s isEqual:GETDOSSIER_API]) {
//		_document = answer.copy;
		[self displayDocumentAt:0];

		self.navigationController.navigationBar.topItem.title = _document.unwrappedName;

		NSArray *buttons;

		if (_dossier.unwrappedDocuments.count > 1)
			buttons = @[_actionButton, _documentsButton, _detailsButton];
		else
			buttons = @[_actionButton, _detailsButton];

		self.navigationItem.rightBarButtonItems = buttons;

//		NSString *documentPrincipal = [[_document[@"documents"] objectAtIndex:0] objectForKey:@"downloadUrl"];
//		[[ADLSingletonState sharedSingletonState] setCurrentPrincipalDocPath:documentPrincipal];
//		NSLog(@"%@", _document[@"actions"]);
//
//		if ([[_document[@"actions"] objectForKey:@"sign"] isEqualToNumber:@YES]) {
//			if ([_document[@"actionDemandee"] isEqualToString:@"SIGNATURE"]) {
//				NSDictionary *signInfoArgs = @{@"dossiers" : @[_dossierRef]};
//				ADLRequester *requester = [ADLRequester sharedRequester];
//				[requester request:@"getSignInfo"
//				           andArgs:signInfoArgs
//					      delegate:self];
//			}
//			else {
//				_visaEnabled = YES;
//				_signatureFormat = nil;
//			}
//		}

		SHOW_HUD
	}
	else if ([s isEqualToString:@"getSignInfo"]) {
		_signatureFormat = [[answer[_dossierRef] objectForKey:@"format"] copy];
	}
	else if ([s isEqualToString:GETANNOTATIONS_API]) {
		NSArray *annotations = [answer[@"annotations"] copy];

		_annotations = annotations;

		for (NSNumber *contentViewIdx in [_readerViewController getContentViews]) {
			ReaderContentView *currentReaderContentView = [_readerViewController getContentViews][contentViewIdx];
			[[currentReaderContentView getContentPage] refreshAnnotations];
		}
	}
	else if ([s isEqualToString:@"addAnnotation"]) {
		API_GETANNOTATIONS(_dossierRef);
	}
	else if ([s isEqual:GETCIRCUIT_API]) {
		self.circuit = answer[@"circuit"];
		API_GETANNOTATIONS(_dossierRef);
	}
}


- (void)didEndWithUnReachableNetwork {

	HIDE_HUD
}


- (void)didEndWithUnAuthorizedAccess {

	HIDE_HUD
}


#pragma mark - NotificationCenter selectors


- (void)dossierSelected:(NSNotification *)notification {

	NSString *dossierRef = [notification object];

	_dossierRef = dossierRef;

	SHOW_HUD

	__weak typeof(self) weakSelf = self;
	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		[_restClient getDossier:[[ADLSingletonState sharedSingletonState] bureauCourant]
		                dossier:_dossierRef
		                success:^(Dossier *result) {
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
				                strongSelf.circuit = [@[circuit] mutableCopy];
				                //[strongSelf requestAnnotations];
			                }
		                }
		                failure:^(NSError *error) {
			                NSLog(@"getCircuit fail : %@", error.localizedDescription);
		                }];
	}
	else {
		API_GETDOSSIER(_dossierRef, [ADLSingletonState sharedSingletonState].bureauCourant);
		API_GETCIRCUIT(_dossierRef);
	}

	//[[self navigationController] popToRootViewControllerAnimated:YES];
}


- (void)showDocumentWithIndex:(NSNotification *)notification {

	NSNumber *docIndex = [notification object];
	[self displayDocumentAt:[docIndex integerValue]];
	[_documentsPopover dismissPopoverAnimated:YES];
	_documentsPopover = nil;
}


- (void)clearDetail:(NSNotification *)notification {

	[self dismissReaderViewController:_readerViewController];

	// Hide title

	self.navigationController.navigationBar.topItem.title = nil;

	// Hide Buttons

	NSArray *buttons = @[];
	self.navigationItem.rightBarButtonItems = buttons;

	// Hide popovers

	if (_documentsPopover != nil)
		[_documentsPopover dismissPopoverAnimated:NO];

	if (_actionPopover != nil)
		[_actionPopover dismissPopoverAnimated:NO];
}


#pragma mark - Split view


- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController {

	barButtonItem.title = @"Dossiers";
	barButtonItem.tintColor = [UIColor darkBlueColor];

//	[self.navigationItem setLeftBarButtonItem:barButtonItem
//									 animated:YES];
//	self.masterPopoverController = popoverController;
}


- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {

	// Called when the view is shown again in the split view, invalidating the button and popover controller.
//	[self.navigationItem setLeftBarButtonItem:nil
//									 animated:YES];

//	self.masterPopoverController = nil;
}


#pragma mark - Private methods


- (void)deleteEveryBinFile {

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//here everything you want to perform in background

		// The preferred way to get the apps documents directory

		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *docDirectory = documentsPaths[0];

		// Grab all the files in the documents dir

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:docDirectory
		                                                     error:nil];

		// Filter the array for only bin files

		NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.bin'"];
		NSArray *binFiles = [allFiles filteredArrayUsingPredicate:fltr];

		// Use fast enumeration to iterate the array and delete the files

		for (NSString *binFile in binFiles) {
			NSError *error = nil;
			[fileManager removeItemAtPath:[docDirectory stringByAppendingPathComponent:binFile]
			                        error:&error];
		}
	});
}


- (NSString *)getFilePathWithDossierRef:(NSString *)dossierRef {

	// The preferred way to get the apps documents directory

	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = documentsPaths[0];

	// Grab all the files in the documents dir

	NSString *fileName = [NSString stringWithFormat:@"%@.bin",
	                                                _dossierRef];
	NSString *filePath = [docDirectory stringByAppendingPathComponent:fileName];

	return filePath;
}


- (NSURL *)getFileUrlWithDossierRef:(NSString *)dossierRef {

	NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
	                                                                      inDomain:NSUserDomainMask
	                                                             appropriateForURL:nil
	                                                                        create:YES
	                                                                         error:nil];

	NSString *fileName = [NSString stringWithFormat:@"%@.bin",
	                                                dossierRef];
	documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:fileName];

	return documentsDirectoryURL;
}


- (void)requestAnnotations {

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		NSString *documentId = _document.unwrappedId;
		
		__weak typeof(self) weakSelf = self;
		[_restClient getAnnotations:_dossierRef
		                   document:documentId
		                    success:^(NSArray *annotations) {

		                        __strong typeof(weakSelf) strongSelf = weakSelf;
		                        if (strongSelf) {
			                        strongSelf.annotations = annotations;

			                        for (NSNumber *contentViewIdx in strongSelf.readerViewController.getContentViews) {
				                        ReaderContentView *currentReaderContentView = strongSelf.readerViewController.getContentViews[contentViewIdx];
				                        [currentReaderContentView.getContentPage refreshAnnotations];
			                        }
		                        }
		                    }
		                    failure:^(NSError *error) {
			                    NSLog(@"getAnnotations error");
		                    }];
	}
	else {
		ADLRequester *requester = [ADLRequester sharedRequester];
		NSDictionary *args = @{@"dossier" : _dossierRef};
		[requester request:GETANNOTATIONS_API
		           andArgs:args
		          delegate:self];
	}
}


- (void)requestSignInfoForDossier:(Dossier *)dossier {

	if ([dossier.unwrappedActions containsObject:@"SIGNATURE"]) {
		if ([dossier.unwrappedActionDemandee isEqualToString:@"SIGNATURE"]) {
			if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
				__weak typeof(self) weakSelf = self;
				[_restClient getSignInfoForDossier:_dossierRef
				                         andBureau:[ADLSingletonState sharedSingletonState].bureauCourant
						                   success:^(ADLResponseSignInfo *signInfo) {
						                       __strong typeof(weakSelf) strongSelf = weakSelf;
						                       if (strongSelf) {
							                       strongSelf.signatureFormat = signInfo.signatureInformations[@"format"];
						                       }
						                   }
						                   failure:^(NSError *error) {
						                       NSLog(@"getSignInfo %@", error.localizedDescription);
						                   }];
			}
			else {
				SHOW_HUD
				NSDictionary *signInfoArgs = @{@"dossiers" : @[_dossierRef]};
				ADLRequester *requester = [ADLRequester sharedRequester];
				[requester request:@"getSignInfo"
				           andArgs:signInfoArgs
				          delegate:self];
			}
		}
		else {
			_visaEnabled = YES;
			_signatureFormat = nil;
		}
	}
}


- (void)loadPdfAt:(NSString *)filePath {

	_readerDocument = [ReaderDocument withDocumentFilePath:filePath
	                                              password:nil];

	if (_readerDocument != nil) // Must have a valid ReaderDocument object in order to proceed with things
	{
		// Deleting previous child controller

		_readerViewController.delegate = nil;
		_readerViewController.dataSource = nil;
		[_readerViewController willMoveToParentViewController:nil];
		[_readerViewController.view removeFromSuperview];
		[_readerViewController removeFromParentViewController];
		_readerViewController = nil;

		// Creating new child controller

		_readerViewController = [[ReaderViewController alloc] initWithReaderDocument:_readerDocument];
		_readerViewController.delegate = self;
		_readerViewController.dataSource = self;
		_readerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
		_readerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[self.view setAutoresizesSubviews:YES];
		[self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

		[self addChildViewController:_readerViewController];
		[self.view addSubview:_readerViewController.view];
	}
	else // Log an error so that we know that something went wrong
	{
		NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:nil] failed.", __FUNCTION__, filePath);
	}
}


- (void)displayDocumentAt:(NSInteger)index {

	_isDocumentPrincipal = (index == 0);
	_document = _dossier.unwrappedDocuments[(NSUInteger) index];
	NSString *documentId = [_document unwrappedId];
	
	// File cache

	NSString *filePath = [self getFileUrlWithDossierRef:documentId].path;
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
	
	if (_dossier.unwrappedDocuments) {
		bool isPdf = (bool) _document.isVisuelPdf;

		[_restClient downloadDocument:documentId
		                        isPdf:isPdf
		                       atPath:[self getFileUrlWithDossierRef:documentId]
		                      success:^(NSString *string) {
			                      HIDE_HUD
			                      [self loadPdfAt:string];
			                      [self requestAnnotations];
		                      }
		                      failure:^(NSError *error) {
			                      HIDE_HUD
			                      [DeviceUtils logError:error];
		                      }];
	}
}


- (void)didEndWithDocument:(ADLDocument *)document {

	HIDE_HUD
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//here everything you want to perform in background

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSFileHandle *file;

		NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

		NSString *docPath = documentsPaths[0];
		NSString *filePath = [NSString stringWithFormat:@"%@/%@.bin",
		                                                docPath,
		                                                _dossierRef];
		[fileManager createFileAtPath:filePath
		                     contents:nil
		                   attributes:nil];

	    file = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[file writeData:document.documentData];

		dispatch_async(dispatch_get_main_queue(), ^{
			//call back to main queue to update user interface
			[self loadPdfAt:filePath];
			[self requestAnnotations];
		});
	});
}


@end
