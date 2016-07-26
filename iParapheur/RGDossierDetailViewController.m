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
#import "RGMasterViewController.h"
#import "ADLNotifications.h"
#import "ADLRequester.h"
#import "ADLCircuitCell.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>


@interface RGDossierDetailViewController () {
	NSMutableArray *_objects;
	__weak UIPopoverController *documentsPopover;
}
@end


@implementation RGDossierDetailViewController

@synthesize detailViewController;
@synthesize dossierRef;
@synthesize typeLabel;
@synthesize sousTypeLabel;
@synthesize circuitLabel;
@synthesize circuitTable;


- (void)awakeFromNib {

	documents = [[NSArray alloc] init];
	[super awakeFromNib];
}


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGDossierDetailViewController");

	_restClient = [ADLRestClient sharedManager];

	self.navigationItem.rightBarButtonItem = nil;
	_objects = [[NSMutableArray alloc] init];

	[self hidesEveryThing];
	self.navigationBar.topItem.title = _dossier[@"titre"];
	self.typeLabel.text = _dossier[@"type"];
	self.sousTypeLabel.text = _dossier[@"sousType"];
	documents = _dossier[@"documents"];

	if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue] >= 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getCircuit:dossierRef
		                success:^(ADLResponseCircuit *responseCircuit) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                NSMutableArray *responseArray = [[NSMutableArray alloc] init];
				                [responseArray addObjectsFromArray:responseCircuit.etapes];

				                [strongSelf refreshCircuits:responseArray];
			                }
		                }
		                failure:^(NSError *error) {
			                NSLog(@"getCircuit error : %@", error);
		                }];
	}
	else {
		dossierRef = _dossier[@"dossierRef"];
		[self getCircuit];
	}

	[self showsEveryThing];
}


- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	if (![self.view.window.gestureRecognizers containsObject:self.tapRecognizer]) {
		self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
		                                                             action:@selector(handleTapBehind:)];
		[self.tapRecognizer setNumberOfTapsRequired:1];
		self.tapRecognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
		[self.view.window addGestureRecognizer:self.tapRecognizer];

	}
}


- (void)didReceiveMemoryWarning {

	[self setCircuitTable:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super didReceiveMemoryWarning];
}


// Hide the modal if tap behind it
- (void)handleTapBehind:(UITapGestureRecognizer *)sender {

	if (sender.state == UIGestureRecognizerStateEnded) {
		CGPoint location = [sender locationInView:nil];

		if (![self.view pointInside:[self.view convertPoint:location
		                                           fromView:self.view.window]
		                  withEvent:nil]) {
			[self dismissModal];
		}
	}
}


- (IBAction)handleClose:(id)sender {

	[self dismissModal];
}


- (void)dismissModal {

	[self.view.window removeGestureRecognizer:self.tapRecognizer];
	[self dismissViewControllerAnimated:YES
	                         completion:NULL];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
		return YES;
	}
}


- (void)dossierSelected:(NSNotification *)notification {

	NSString *selectedDossierRef = [notification object];
	[self setDossierRef:selectedDossierRef];
}


- (void)setDossierRef:(NSString *)_dossierRef {

	dossierRef = _dossierRef;

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
		                dossier:dossierRef
		                success:^(Dossier *responseDossier) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                [ADLSingletonState sharedSingletonState].dossierCourantObject = responseDossier;
				                [strongSelf getDossierDidEndWithREquestAnswer];
			                }
		                }
		                failure:^(NSError *error) {
			                NSLog(@"getDossier error %@ : ", error.localizedDescription);
		                }];
	}
	else {
		NSDictionary *args = @{@"dossierRef" : _dossierRef};

		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:GETDOSSIER_API
		           andArgs:args
		          delegate:self];
	}

	SHOW_HUD
}


#pragma mark - Table View


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	return _objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *CellIdentifier = @"CircuitCell";
	ADLCircuitCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// TODO Adrien : check

	if (cell == nil) {
		cell = [[ADLCircuitCell alloc] init];
	}

	NSDictionary *object = _objects[(NSUInteger) indexPath.row];
	// cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [object objectForKey:@"parapheurName"], [object objectForKey:@"actionDemandee"]];

	cell.parapheurName.text = object[@"parapheurName"];
	if ([object[@"approved"] intValue] == 1) {
		cell.validateurName.text = object[@"signataire"];
		cell.annotation.text = object[@"annotPub"];
	}
	else {
		cell.validateurName.text = @"";
		cell.annotation.text = @"";
	}

	ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];

	if (object[@"dateValidation"]) {

		NSDate *validationDate;

		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
			if ([object[@"dateValidation"] isKindOfClass:[NSNumber class]]) {
				NSNumber *dateMs = object[@"dateValidation"];
				validationDate = [NSDate dateWithTimeIntervalSince1970:dateMs.doubleValue / 1000];
			}
		}
		else {
			NSString *validationDateIso = object[@"dateValidation"];
			if (validationDateIso != nil && ![validationDateIso isEqualToString:@""])
				validationDate = [formatter dateFromString:validationDateIso];
		}

		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		outputFormatter.dateFormat = @"'le' dd/MM/yyyy 'à' HH:mm";

		NSString *validationDateStr = [outputFormatter stringFromDate:validationDate];

		cell.validationDate.text = validationDateStr;
	}
	else {
		cell.validationDate.text = nil;
	}


	NSString *imagePrefix = @"iw";
	if ([object[@"rejected"] intValue] == 1) {
		imagePrefix = @"ir";
	}
	else if ([object[@"approved"] intValue] == 1) {
		imagePrefix = @"ip";
	}

	NSString *action = [object[@"actionDemandee"] lowercaseString];

	cell.etapeTypeIcon.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@-%@.png",
	                                                                          imagePrefix,
	                                                                          action]];

	return cell;
}


- (BOOL)    tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the specified item to be editable.
	return YES;
}


- (void) tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath {

	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[_objects removeObjectAtIndex:(NSUInteger) indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath]
		                 withRowAnimation:UITableViewRowAnimationFade];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
	}
}


- (IBAction)showDocumentsViewController:(id)sender {

	if (documentsPopover)
		[documentsPopover dismissPopoverAnimated:YES];
	else
		[self performSegueWithIdentifier:@"showDocumentsView"
		                          sender:sender];
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		NSDate *object = _objects[(NSUInteger) indexPath.row];
		self.detailViewController.detailItem = object;
	}
}


- (void)getCircuit {

	ADLRequester *requester = [ADLRequester sharedRequester];
	NSDictionary *args = @{@"dossier" : dossierRef};
	[requester request:@"getCircuit"
	           andArgs:args
	          delegate:self];

	SHOW_HUD
}


#pragma mark - Request Callback


- (void)getDossierDidEndWithREquestAnswer {
	//[deskArray removeAllObjects];
	@synchronized (self) {
		//[textView setText:[answer JSONString]];
		//[self refreshViewWithDossier:[answer objectForKey:@"data"]];
	}
	[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];

	[self getCircuit];
	[self showsEveryThing];
}


#pragma mark - Wall impl


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSString *s = answer[@"_req"];

	if ([s isEqual:GETDOSSIER_API]) {
		[self getDossierDidEndWithREquestAnswer];
	}
	else if ([s isEqualToString:@"getCircuit"]) {
		[self refreshCircuits:answer[@"circuit"]];
	}
}


- (void)didEndWithUnReachableNetwork {

}


- (void)didEndWithUnAuthorizedAccess {

}


#pragma mark - View Refresh with data


- (void)refreshCircuits:(NSArray *)circuitArray {

	@synchronized (self) {
		[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];

		[_objects removeAllObjects];
		[_objects addObjectsFromArray:circuitArray];
		[circuitTable reloadData];
	}
}


#pragma mark - IBActions


- (IBAction)showVisuelPDF:(id)sender {

	NSArray *pdfs = [[NSBundle mainBundle] pathsForResourcesOfType:@"pdf"
	                                                   inDirectory:nil];

	NSString *filePath = pdfs.lastObject;

	ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:filePath
	                                                           password:nil];

	readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
	readerViewController.delegate = self;

	readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;

	[self.splitViewController presentViewController:readerViewController
	                                       animated:YES
	                                     completion:nil];
}


- (void)dismissReaderViewController:(ReaderViewController *)viewController {
	// do nothing for now
	[self.splitViewController dismissViewControllerAnimated:YES
	                                             completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	/*
	 if ([[segue identifier] isEqualToString:@"showDocumentsView"]) {
	 
	 if (documentsPopover) {
	 [documentsPopover dismissPopoverAnimated:NO];
	 [documentsPopover release];
	 documentsPopover = nil;
	 }
	 documentsPopover = [[(UIStoryboardPopoverSegue *)segue popoverController] retain];
	 
	 [((RGDocumentsView
	 *)[segue destinationViewController]) setDocuments:documents];
	 
	 [((RGDocumentsView
	 *)[segue destinationViewController]) setSplitViewController:[self splitViewController]];
	 
	 [((RGDocumentsView
	 *)[segue destinationViewController]) setPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
	 }*/
}


- (void)presentModalViewController:(UIViewController *)modalViewController
                          animated:(BOOL)animated {

	[super presentModalViewController:modalViewController
	                         animated:animated];
}


- (void)hidesEveryThing {

	self.hiddenForEveryone = YES;
}


- (void)showsEveryThing {

	self.hiddenForEveryone = NO;
}


- (void)setHiddenForEveryone:(BOOL)val {

	dossierName.hidden = val;
	typeLabel.hidden = val;
	sousTypeLabel.hidden = val;
	circuitTable.hidden = val;
	circuitLabel.hidden = val;
}


#pragma mark - LGViewHUDDelegate


- (void)shallDismissHUD:(LGViewHUD *)hud {

	HIDE_HUD
}


@end
