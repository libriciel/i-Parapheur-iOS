/*
 * Contributors : SKROBS (2012)
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
#import "iParapheur-Swift.h"


@interface RGDossierDetailViewController () {
	NSMutableArray *_objects;
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

	documents = [NSArray new];
	[super awakeFromNib];
}


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGDossierDetailViewController");

	_restClient = ADLRestClient.sharedManager;

	self.navigationItem.rightBarButtonItem = nil;
	_objects = NSMutableArray.new;

	[self hidesEveryThing];
	self.navigationBar.topItem.title = _dossier[@"titre"];
	self.typeLabel.text = _dossier[@"type"];
	self.sousTypeLabel.text = _dossier[@"sousType"];
	documents = _dossier[@"documents"];

	if ([ADLRestClient.sharedManager getRestApiVersion].intValue >= 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getCircuit:dossierRef
		                success:^(Circuit *retrievedCircuit) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                [strongSelf refreshCircuits:retrievedCircuit.etapes];
			                }
		                }
		                failure:^(NSError *error) {
			                NSLog(@"getCircuit error : %@", error);
		                }];
	}
	else {
		dossierRef = _dossier[@"dossierRef"];
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
	[NSNotificationCenter.defaultCenter removeObserver:self];

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


- (void)setDossierRef:(NSString *)_dossierRef {

	dossierRef = _dossierRef;

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

	SHOW_HUD
}


#pragma mark - Table View


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    WorkflowStepCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CircuitCell"];
    Etape *step = _objects[(NSUInteger) indexPath.row];

    cell.deskTextView.text = step.parapheurName;
    cell.userTextView.text = step.signataire;
    cell.publicAnnotationTextView.text = step.annotPub;

	if (step.dateValidation != nil) {
		cell.dateTextView.text = [StringsUtils prettyPrintWithDate:step.dateValidation];
	} else {
        cell.dateTextView.text = @"";
	}

	// Image

    NSString *imageName = [ViewUtils getImageNameWithAction:step.actionDemandee];
    UIImage *image = [UIImage imageNamed:imageName];
    UIImage *tintedImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [cell.stepIconImageView setImage:tintedImage];
    cell.stepIconImageView.tintColor = [ColorUtils getColorWithAction:step.actionDemandee];

    //

	return cell;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	return _objects.count;
}


#pragma mark - Request Callback


- (void)getDossierDidEndWithREquestAnswer {
	//[deskArray removeAllObjects];
	@synchronized (self) {
		//[textView setText:[answer JSONString]];
		//[self refreshViewWithDossier:[answer objectForKey:@"data"]];
	}
	[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];

	[self showsEveryThing];
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


- (void)dismissReaderViewController:(ReaderViewController *)viewController {
	// do nothing for now
	[self.splitViewController dismissViewControllerAnimated:YES
	                                             completion:nil];
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
