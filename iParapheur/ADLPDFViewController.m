/*
 * Version 1.1
 * CeCILL Copyright (c) 2012, SKROBS, ADULLACT-projet
 * Initiated by ADULLACT-projet S.A.
 * Developped by SKROBS
 *
 * contact@adullact-projet.coop
 *
 * Ce logiciel est un programme informatique servant à faire circuler des
 * documents au travers d'un circuit de validation, où chaque acteur vise
 * le dossier, jusqu'à l'étape finale de signature.
 *
 * Ce logiciel est régi par la licence CeCILL soumise au droit français et
 * respectant les principes de diffusion des logiciels libres. Vous pouvez
 * utiliser, modifier et/ou redistribuer ce programme sous les conditions
 * de la licence CeCILL telle que diffusée par le CEA, le CNRS et l'INRIA
 * sur le site "http://www.cecill.info".
 *
 * En contrepartie de l'accessibilité au code source et des droits de copie,
 * de modification et de redistribution accordés par cette licence, il n'est
 * offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
 * seule une responsabilité restreinte pèse sur l'auteur du programme,  le
 * titulaire des droits patrimoniaux et les concédants successifs.
 *
 * A cet égard  l'attention de l'utilisateur est attirée sur les risques
 * associés au chargement,  à l'utilisation,  à la modification et/ou au
 * développement et à la reproduction du logiciel par l'utilisateur étant
 * donné sa spécificité de logiciel libre, qui peut le rendre complexe à
 * manipuler et qui le réserve donc à des développeurs et des professionnels
 * avertis possédant  des  connaissances  informatiques approfondies.  Les
 * utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
 * logiciel à leurs besoins dans des conditions permettant d'assurer la
 * sécurité de leurs systèmes et ou de leurs données et, plus généralement,
 * à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.
 *
 * Le fait que vous puissiez accéder à cet en-tête signifie que vous avez
 * pris connaissance de la licence CeCILL, et que vous en avez accepté les
 * termes.
 */

//
//  ADLPDFViewController.m
//  iParapheur
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
#import "UIColor+CustomColors.h"
#import "ADLResponseCircuit.h"
#import "ADLResponseDossier.h"
#import "ADLResponseAnnotation.h"
#import "ADLResponseSignInfo.h"


#define kActionButtonsWidth 300.0f
#define kActionButtonsHeight 100.0f

@interface ADLPDFViewController ()

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)configureView;

@end


@implementation ADLPDFViewController

#pragma mark - Managing the detail item


-(void)setDetailItem:(id)newDetailItem {
	if (_detailItem != newDetailItem) {
		_detailItem = newDetailItem;
		
		// Update the view.
		[self configureView];
	}
	
	if (self.masterPopoverController != nil) {
		[self.masterPopoverController dismissPopoverAnimated:YES];
	}
}


-(void)configureView {
	// Update the user interface for the detail item.hide
	
}


-(void)viewDidLoad {
	[super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
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
	
	self.navigationItem.rightBarButtonItem = nil;
	//self.navigationItem.leftBarButtonItem = nil;
	//self.actions = [NSMutableArray new];
	[self configureView];
	
	_restClient = [[ADLRestClient alloc] init];
}


-(void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


#pragma mark - Reset view state


-(void)resetViewState {
	for(UIView *subview in [self.view subviews]) {
		[subview removeFromSuperview];
	}
	
	[[self navigationController] popToRootViewControllerAnimated:YES];
	
	//self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.rightBarButtonItems = nil;
	//self.navigationItem.leftBarButtonItem = nil;
	
	[_actionPopover dismissPopoverAnimated:YES];
	[_documentsPopover dismissPopoverAnimated:YES];
	_documentsPopover = nil;
	_actionPopover = nil;
	_readerViewController = nil;
	//_actionsCollectionView = nil;
	
}


#pragma mark - selector for observer


-(void)clearDetail: (NSNotification*) notification {
	[self resetViewState];
}


-(void)dossierSelected: (NSNotification*) notification {
	NSString *dossierRef = [notification object];
	_dossierRef = dossierRef;
		
	for(UIView *subview in [self.view subviews]) {
		[subview removeFromSuperview];
	}
	
	SHOW_HUD
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[_restClient getDossier:[[ADLSingletonState sharedSingletonState] bureauCourant]
						dossier:_dossierRef
						success:^(NSArray *result) {
							HIDE_HUD
							[self getDossierDidEndWithRequestAnswer:result[0]];
						}
						failure:^(NSError *error) {
							NSLog(@"getBureau fail : %@", error.localizedDescription);
						}];
		
		[_restClient getCircuit:_dossierRef
						success:^(NSArray *circuits) {
							HIDE_HUD
							_circuit = circuits;
							[self refreshAnnotations:dossierRef];
						}
						failure:^(NSError *error) {
							NSLog(@"getCircuit fail : %@", error.localizedDescription);
						}];
	}
	else {
		API_GETDOSSIER(_dossierRef, [[ADLSingletonState sharedSingletonState] bureauCourant]);
		API_GETCIRCUIT(_dossierRef);
	}
	
	[[self navigationController] popToRootViewControllerAnimated:YES];
}


-(void)showDocumentWithIndex:(NSNotification*) notification {
	NSNumber* docIndex = [notification object];
	[self displayDocumentAt:[docIndex integerValue]];
	[_documentsPopover dismissPopoverAnimated:YES];
	_documentsPopover = nil;
	
}


#pragma mark - Rest calls for API3


-(void)refreshAnnotations:(NSString*)dossier {
	
	[_restClient getAnnotations:_dossierRef
						success:^(NSArray *annotations) {
							_annotations = annotations;
							
							for (NSNumber *contentViewIdx in [_readerViewController contentViews])
								[[[[_readerViewController contentViews] objectForKey:contentViewIdx] contentPage] refreshAnnotations];
							
						} failure:^(NSError *error) {
							NSLog(@"getAnnotations error : %@", error.localizedDescription);
						}];
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

	[self refreshSignInfoForDossier:dossier];
}


-(void)refreshSignInfoForDossier:(ADLResponseDossier*)dossier {

	SHOW_HUD
	
	if ([dossier.actions containsObject:@"SIGNATURE"]) {
		if ([dossier.actionDemandee isEqualToString:@"SIGNATURE"]) {
			if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
				[_restClient getSignInfoForDossier:_dossierRef
										 andBureau:[[ADLSingletonState sharedSingletonState] bureauCourant]
										   success:^(NSArray *signInfos) {
											   if (signInfos.count > 0)
												   _signatureFormat = [((ADLResponseSignInfo*) signInfos[0]).signatureInformations objectForKey:@"format"];
											   else
												   _signatureFormat = nil;
										   }
										   failure:^(NSError *error) {
											   NSLog(@"getSignInfo %@", error.localizedDescription);
										   }];
			}
			else {
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


#pragma mark - Wall delegate Implementation


-(void)displayDocumentAt: (NSInteger) index {
	
	SHOW_HUD
	
	_isDocumentPrincipal = (index == 0);
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	if (([[ADLRestClient getRestApiVersion] intValue ] == 3) && _document) {
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
		
		for (NSNumber *contentViewIdx in [_readerViewController contentViews])
			[[[[_readerViewController contentViews] objectForKey:contentViewIdx] contentPage] refreshAnnotations];
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
	
}


-(void)didEndWithUnAuthorizedAccess {
	
}


-(void)didEndWithDocument:(ADLDocument*)document {
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSFileHandle *file;
	
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	NSString *docPath = [documentsPaths objectAtIndex:0];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", docPath, @"myfile.bin"];
	[fileManager createFileAtPath:filePath
						 contents:nil
					   attributes:nil];
	
	file = [NSFileHandle fileHandleForWritingAtPath:filePath];
	[file writeData:[document documentData]];
	
	ReaderDocument *readerDocument = [[ReaderDocument alloc] initWithFilePath:filePath password:nil];
	
	_readerViewController = [[ReaderViewController alloc] initWithReaderDocument:readerDocument];
	
	[_readerViewController setDataSource:self];
	[_readerViewController setAnnotationsEnabled:_isDocumentPrincipal];
	
	_readerViewController.delegate = self;
	_readerViewController.view.frame = [[self view] frame];
	
	[_readerViewController.view setAutoresizingMask:( UIViewAutoresizingFlexibleWidth |
													 UIViewAutoresizingFlexibleHeight )];
	[[self view] setAutoresizesSubviews:YES];
	
	for(UIView *subview in [self.view subviews]) {
		[subview removeFromSuperview];
	}
	
	[[self view] addSubview:[_readerViewController view]];
	
	HIDE_HUD
	
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:_dossierRef, @"dossier", nil];
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[self refreshAnnotations:_dossierRef];
	}
	else {
		[requester request:GETANNOTATIONS_API andArgs:args delegate:self];
	}
}


-(void)dismissReaderViewController:(ReaderViewController *)viewController {
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
	
#if (DEMO_VIEW_CONTROLLER_PUSH == TRUE)
	
	[self.navigationController popViewControllerAnimated:YES];
	
#else // dismiss the modal view controller
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
#endif // DEMO_VIEW_CONTROLLER_PUSH
}


-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
							   duration:(NSTimeInterval)duration {
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[_readerViewController updateScrollViewContentViews];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue
				sender:(id)sender {
	
	if ([[segue identifier] isEqualToString:@"dossierDetails"]) {
		
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3)
			[((RGDossierDetailViewController*) [segue destinationViewController]) setDossierRef:_dossierRef];
		else
			[((RGDossierDetailViewController*) [segue destinationViewController]) setDossier:_document];
	}
	
	if ([[segue identifier] isEqualToString:@"showDocumentPopover"]) {
		[((RGDocumentsView*)[segue destinationViewController]) setDocuments:[_document objectForKey:@"documents"]];
		if (_documentsPopover != nil) {
			[_documentsPopover dismissPopoverAnimated:NO];
		}
		
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


-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
	if (_documentsPopover != nil && _documentsPopover == popoverController) {
		_documentsPopover = nil;
	}
	else if (_actionPopover != nil && _actionPopover == popoverController) {
		_actionPopover = nil;
	}
}


-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)viewDidUnload {
	[super viewDidUnload];
}


#pragma mark - Annotations Drawing view data Source


-(NSArray*)annotationsForPage:(NSInteger)page {
	
	NSMutableArray *annotsAtPage = [[NSMutableArray alloc] init];
	
	int i = 0; // etapeNumber
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		for (ADLResponseAnnotation *etape in _annotations) {
			NSArray *annotationsAtPageForEtape = [etape.data objectForKey:[NSString stringWithFormat:@"%d", page]];
			
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
			NSArray *annotationsAtPageForEtape = [etape objectForKey:[NSString stringWithFormat:@"%d", page]];
			
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
							  forPage:page
						   forDossier:[[ADLSingletonState sharedSingletonState] dossierCourant]
							  success:^(NSArray *result) {
								  NSLog(@"updateAnnotation success");
							  }
							  failure:^(NSError *error) {
								  NSLog(@"updateAnnotation error : %@", error.localizedDescription);
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
								  NSLog(@"deleteAnnotation error : %@", error.localizedDescription);
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
		NSString *login=[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"login_preference"];
		
		NSDictionary *args = [annotation dict];
		[args setValue:[NSNumber numberWithUnsignedInteger:page] forKey:@"page"];
		[args setValue:[NSDate date] forKey:@"date"];
		[args setValue:@"rect" forKey:@"type"];
		[args setValue:login forKey:@"author"];
		
		[_restClient addAnnotations:args
						 forDossier:[[ADLSingletonState sharedSingletonState] dossierCourant]
							success:^(NSArray *result) {
								[self refreshAnnotations:_dossierRef];
							}
							failure:^(NSError *error) {
								NSLog(@"AddAnnotation error : %@", error.localizedDescription);
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


-(void)shallDismissHUD:(LGViewHUD*)hud {
	HIDE_HUD
}


#pragma mark - Split view


-(void)splitViewController:(UISplitViewController *)splitController
	willHideViewController:(UIViewController *)viewController
		 withBarButtonItem:(UIBarButtonItem *)barButtonItem
	  forPopoverController:(UIPopoverController *)popoverController {
	
	barButtonItem.title = NSLocalizedString(@"Dossiers", @"Dossiers");
	barButtonItem.tintColor = [UIColor colorWithRed:0.0f
											  green:0.375f
											   blue:0.75f
											  alpha:1.0f];
	
	[self.navigationItem setLeftBarButtonItem:barButtonItem
									 animated:YES];
	self.masterPopoverController = popoverController;
}


-(void)splitViewController:(UISplitViewController *)splitController
	willShowViewController:(UIViewController *)viewController
 invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	
	// Called when the view is shown again in the split view, invalidating the button and popover controller.
	[self.navigationItem setLeftBarButtonItem:nil
									 animated:YES];
	
	self.masterPopoverController = nil;
}


@end
