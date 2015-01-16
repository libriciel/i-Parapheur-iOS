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
//  RGMasterViewController.m
//  iParapheur
//
//

#import "RGMasterViewController.h"
#import "RGMasterViewController.h"
#import "RGReaderViewController.h"
#import "RGAppDelegate.h"
#import "RGDocumentsView.h"
#import "ADLNotifications.h"
#import "ADLRequester.h"
#import "ADLCredentialVault.h"
#import "ADLCollectivityDef.h"
#import "ADLCircuitCell.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>

#import "LGViewHUD.h"

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
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		/* self.clearsSelectionOnViewWillAppear = NO;*/
		self.preferredContentSize = CGSizeMake(320.0, 600.0);
	}
	documents = [[NSArray alloc] init];
	[super awakeFromNib];
}


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGDossierDetailViewController");
	
	_restClient = [[ADLRestClient alloc] init];
	
	self.navigationItem.rightBarButtonItem=nil;
	_objects = [[NSMutableArray alloc] init];
	
	[self hidesEveryThing];
	self.navigationBar.topItem.title = [_dossier objectForKey:@"titre"];
	[[self typeLabel] setText:[_dossier objectForKey:@"type"]];
	[[self sousTypeLabel] setText:[_dossier objectForKey:@"sousType"]];
	documents = [_dossier objectForKey:@"documents"];
	
	// V2/V3 swtich
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		dossierRef = [_dossier objectForKey:@"id"];
		
		[_restClient getCircuit:dossierRef
						success:^(NSArray *circuitArray) {
							[self refreshCircuits:circuitArray];
						}
						failure:^(NSError *error) {
							NSLog(@"getCircuit error : %@", error);
						}];
	}
	else {
		dossierRef = [_dossier objectForKey:@"dossierRef"];
		[self getCircuit];
	}
	
	[self showsEveryThing];
}


- (void)viewDidAppear:(BOOL)animated {
	if(![self.view.window.gestureRecognizers containsObject:self.tapRecognizer])
	{
		self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
		[self.tapRecognizer setNumberOfTapsRequired:1];
		self.tapRecognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
		[self.view.window addGestureRecognizer:self.tapRecognizer];
		
	}
}


- (void)viewDidUnload {
	[self setCircuitTable:nil];
	
	//unregister observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
	// Release any retained subviews of the main view.
}


// Hide the modal if tap behind it
- (void) handleTapBehind:(UITapGestureRecognizer*) sender {
	if (sender.state == UIGestureRecognizerStateEnded)
	{
		CGPoint location = [sender locationInView:nil];
		
		if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil])
		{
			[self dismissModal];
		}
	}
}


- (IBAction)handleClose:(id)sender {
	[self dismissModal];
}


- (void) dismissModal {
	[self.view.window removeGestureRecognizer:self.tapRecognizer];
	[self dismissViewControllerAnimated:YES completion:NULL];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
		return YES;
	}
}


- (void) dossierSelected:(NSNotification*)notification {
	NSString *selectedDossierRef  = [notification object];
	[self setDossierRef:selectedDossierRef];
}


- (void) setDossierRef:(NSString *)_dossierRef {
	dossierRef = _dossierRef;

	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:_dossierRef, @"dossierRef", nil];
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[_restClient getDossier:dossierRef // TODO
						dossier:dossierRef
						success:^(NSArray *dossier) {
							[self getDossierDidEndWithREquestAnswer];
						}
						failure:^(NSError *error) {
							NSLog(@"getDossier error %@ : ", error.localizedDescription);
						}];
	}
	else {
		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:GETDOSSIER_API andArgs:args delegate:self];
	}

	SHOW_HUD
}

/*
 - (void)insertNewObject:(id)sender
 {
 if (!_objects) {
 _objects = [[NSMutableArray alloc] init];
 }
 [_objects insertObject:[NSDate date] atIndex:0];
 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
 [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
 }*/


#pragma mark - Table View


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"CircuitCell";
	ADLCircuitCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[ADLCircuitCell alloc] init];
	}
	
	NSDictionary *object = [_objects objectAtIndex:indexPath.row];
	// cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [object objectForKey:@"parapheurName"], [object objectForKey:@"actionDemandee"]];
	
	[[cell parapheurName] setText:[object objectForKey:@"parapheurName"]];
	if ([[object objectForKey:@"approved"] intValue] == 1) {
		[[cell validateurName] setText:[object objectForKey:@"signataire"]];
		cell.annotation.text = [object objectForKey:@"annotPub"];
	}
	else {
		cell.validateurName.text= @"";
		cell.annotation.text = @"";
	}
	
	ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
	
	NSString *validationDateIso = [object objectForKey:@"dateValidation"];
	if (validationDateIso != nil && ![validationDateIso isEqualToString:@""]) {
		NSDate * validationDate = [formatter dateFromString:validationDateIso];
		
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateFormat:@"'le' dd/MM/yyyy 'à' HH:mm"];
		
		NSString *validationDateStr = [outputFormatter stringFromDate:validationDate];
		
		[[cell validationDate] setText:validationDateStr];
		
		
	}
	else {
		[[cell validationDate] setText:nil];
	}
	
	
	NSString *imagePrefix = @"iw";
	if ([[object objectForKey:@"rejected"] intValue] == 1) {
		imagePrefix = @"ir";
	}
	else if ([[object objectForKey:@"approved"] intValue] == 1) {
		imagePrefix = @"ip";
	}
	
	
	NSString *action = [[object objectForKey:@"actionDemandee"] lowercaseString];
	
	[[cell etapeTypeIcon] setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-%@.png", imagePrefix, action ]]];
	
	return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return NO if you do not want the specified item to be editable.
	return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[_objects removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
	}
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */
-(IBAction)showDocumentsViewController:(id)sender {
	if (documentsPopover)
		[documentsPopover dismissPopoverAnimated:YES];
	else
		[self performSegueWithIdentifier:@"showDocumentsView" sender:sender];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		NSDate *object = [_objects objectAtIndex:indexPath.row];
		self.detailViewController.detailItem = object;
	}
}


/*
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 if ([[segue identifier] isEqualToString:@"showDetail"]) {
 NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
 NSDate *object = [_objects objectAtIndex:indexPath.row];
 [[segue destinationViewController] setDetailItem:object];
 }
 }*/


-(void)getCircuit {
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:dossierRef,
						  @"dossier", nil];
	
	[requester request:@"getCircuit" andArgs:args delegate:self];
	
	SHOW_HUD
}


#pragma mark - Request Callback


-(void)getDossierDidEndWithREquestAnswer {
	//[deskArray removeAllObjects];
	@synchronized(self)
	{
		//[textView setText:[answer JSONString]];
		//[self refreshViewWithDossier:[answer objectForKey:@"data"]];
	}
	[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
	[self getCircuit];
	[self showsEveryThing];
}


#pragma mark - Wall impl


-(void)didEndWithRequestAnswer:(NSDictionary*)answer{
	NSString *s = [answer objectForKey:@"_req"];
	
	if ([s isEqual:GETDOSSIER_API]) {
		[self getDossierDidEndWithREquestAnswer];
	}
	else if ([s isEqualToString:@"getCircuit"]) {
		[self refreshCircuits:[answer objectForKey:@"circuit"]];
	}
}


-(void)didEndWithUnReachableNetwork{
	
}


-(void)didEndWithUnAuthorizedAccess {
	
}


#pragma mark - View Refresh with data


-(void)refreshCircuits:(NSArray *)circuitArray {
	@synchronized(self)
	{
		[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];

		[_objects removeAllObjects];
		[_objects addObjectsFromArray:circuitArray];
		[circuitTable reloadData];
	}
}


#pragma mark - IBActions


-(IBAction)showVisuelPDF:(id)sender {
	NSArray *pdfs = [[NSBundle mainBundle] pathsForResourcesOfType:@"pdf" inDirectory:nil];
	
	NSString *filePath = [pdfs lastObject];
	
	ReaderDocument *document = [[ReaderDocument alloc] initWithFilePath:filePath password:nil];
	
	readerViewController = [[ReaderViewController alloc] initWithReaderDocument:document];
	[readerViewController setDelegate:self];
	
	readerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	readerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
	
	[[self splitViewController] presentViewController:readerViewController animated:YES completion:nil];
	
}


-(void)dismissReaderViewController:(ReaderViewController *)viewController {
	// do nothing for now
	[[self splitViewController] dismissViewControllerAnimated:YES completion:nil];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
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


-(void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated {
	[super presentModalViewController:modalViewController animated:animated];
}


-(void)hidesEveryThing {
	[self setHiddenForEveryone:YES];
	
}


-(void)showsEveryThing {
	[self setHiddenForEveryone:NO];
}


-(void)setHiddenForEveryone:(BOOL)val {
	[dossierName setHidden:val];
	[typeLabel setHidden:val];
	[sousTypeLabel setHidden:val];
	[circuitTable setHidden:val];
	[circuitLabel setHidden:val];
}


#pragma mark - LGViewHUDDelegate


-(void)shallDismissHUD:(LGViewHUD*)hud {
	HIDE_HUD
}


@end
