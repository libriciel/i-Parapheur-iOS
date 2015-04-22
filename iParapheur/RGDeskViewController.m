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
//  RGDeskViewController.m
//  iParapheur
//
//

#import "RGDeskViewController.h"
#import "RGMasterViewController.h"
#import "RGWorkflowDialogViewController.h"
#import "ADLFilterViewController.h"
#import "LGViewHUD.h"
#import "RGFileCell.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "NSString+Contains.h"
#import "UIColor+CustomColors.h"
#import "ADLAPIHelper.h"
#import "ADLRestClient.h"
#import "ADLResponseDossiers.h"
#import "StringUtils.h"
#import "DeviceUtils.h"


@interface RGDeskViewController()
{
	int _currentPage;
	UIBarButtonItem *moreBarButtonItem;
}

@property (nonatomic, weak) RGFileCell* swipedCell;
@property (nonatomic, assign, getter = isInBatchMode) BOOL inBatchMode;
@property (nonatomic, retain, readonly) NSArray* possibleMainActions;
@property (nonatomic, retain, readonly) NSArray* actionsWithoutAnnotation;
@property (nonatomic, retain) NSString* mainAction;
@property (nonatomic, retain) NSArray* secondaryActions;

@end


@implementation RGDeskViewController


@synthesize inBatchMode = _inBatchMode;


#pragma mark - UIViewController delegate


-(void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGDeskViewController");
	//[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TableViewPaperBackground.png"]]];
	
	[[self.navigationItem backBarButtonItem] setTintColor:[UIColor darkBlueColor]];
	
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl setTintColor:[UIColor selectedCellGreyColor]];
	
	[self.refreshControl addTarget:self
							action:@selector(refresh)
				  forControlEvents:UIControlEventValueChanged];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refresh)
												 name:kDossierActionComplete
											   object:nil];
	
	self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
	[self.searchDisplayController.searchResultsTableView registerClass:[RGFileCell class]
												forCellReuseIdentifier:@"dossierCell"];
	self.inBatchMode = NO;
	
	_restClient = [ADLRestClient sharedManager];
}


-(void)refresh {
	[self.refreshControl beginRefreshing];
	[self loadDossiersWithPage:0];
}


-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:YES];
	
	_currentPage = 0;
	_dossiersArray = [NSMutableArray new];
	_possibleMainActions = [NSArray arrayWithObjects:@"VISER", @"SIGNER", @"TDT", @"MAILSEC", @"ARCHIVER", nil];
	_actionsWithoutAnnotation = [NSArray arrayWithObjects:@"RECUPERER", @"SUPPRIMER", @"SECRETARIAT", nil];
	
	SHOW_HUD
	[self loadDossiersWithPage:_currentPage];
}


-(void)setInBatchMode:(BOOL)value {
	_inBatchMode = value;
}


-(void)loadDossiersWithPage:(int)page {
	
	NSDictionary *currentFilter = [[ADLSingletonState sharedSingletonState] currentFilter];

	if (currentFilter != nil) {
		
		NSMutableArray *types = [NSMutableArray new];
		for (NSString *type in [currentFilter objectForKey:@"types"])
			[types addObject:[NSDictionary dictionaryWithObject:type forKey:@"ph:typeMetier"]];
		
		NSMutableArray *sousTypes = [NSMutableArray new];
		for (NSString *sousType in [currentFilter objectForKey:@"sousTypes"])
			[sousTypes addObject:[NSDictionary dictionaryWithObject:sousType forKey:@"ph:soustypeMetier"]];

		NSDictionary *titre = [NSDictionary dictionaryWithObject:
							   [NSArray arrayWithObject:
								[NSDictionary dictionaryWithObject:
								 [NSString stringWithFormat:@"*%@*", [currentFilter objectForKey:@"titre"]]
														forKey:@"cm:title"]]
														  forKey:@"or"];
		
		NSDictionary *filtersDictionnary = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:types forKey:@"or"],
																										[NSDictionary dictionaryWithObject:sousTypes forKey:@"or"],
																										titre,
																										nil]
																	   forKey:@"and"];
		
		// Send request
		
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
			
			// Stringify JSON filter
			
			NSError *error;
			NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtersDictionnary
															   options:0
																 error:&error];
			
			NSString *jsonString = nil;
			if (jsonData)
				jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		
			// API3 request
			
			__weak typeof(self) weakSelf = self;
			[_restClient getDossiers:self.deskRef
								page:page
								size:15
							  filter:jsonString
							 success:^(NSArray *dossiers) {
								 __strong typeof(weakSelf) strongSelf = weakSelf;
								 if (strongSelf) {
									 NSLog(@"getDossiers success : %lu", (unsigned long)dossiers.count);
									 [strongSelf.refreshControl endRefreshing];
									 HIDE_HUD
									 [strongSelf getDossierDidEndWithSuccess:dossiers];
								 }
							 }
							 failure:^(NSError *error) {
								 __strong typeof(weakSelf) strongSelf = weakSelf;
								 if (strongSelf) {
									 [DeviceUtils logError:error];
									 [strongSelf.refreshControl endRefreshing];
									 HIDE_HUD
								 }
							 }];
		}
		else {
			API_GETDOSSIERHEADERS_FILTERED(self.deskRef, [NSNumber numberWithInteger:page], @"15", [currentFilter objectForKey:@"banette"], filtersDictionnary);
		}
	}
	else {
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
			__weak typeof(self) weakSelf = self;
			[_restClient getDossiers:self.deskRef
								page:page
								size:15
			 				  filter:nil
							 success:^(NSArray *dossiers) {
								 __strong typeof(weakSelf) strongSelf = weakSelf;
								 if (strongSelf) {
									 NSLog(@"getDossiers success : %lu", (unsigned long)dossiers.count);
									 [strongSelf.refreshControl endRefreshing];
									 HIDE_HUD
									 [strongSelf getDossierDidEndWithSuccess:dossiers];
								 }
							 }
							 failure:^(NSError *error) {
								 __strong typeof(weakSelf) strongSelf = weakSelf;
								 if (strongSelf) {
									 [DeviceUtils logError:error];
									 [strongSelf.refreshControl endRefreshing];
									 HIDE_HUD
								 }
							 }];
		}
		else {
			API_GETDOSSIERHEADERS(self.deskRef, [NSNumber numberWithInteger:page], @"15");
		}
	}
}


#pragma mark Actions


-(void)updateToolBar {
	if (self.isInBatchMode) {
		if (self.navigationController.toolbarHidden) {
			[self.navigationController setToolbarHidden:NO
											   animated:YES];
		}
		NSArray *actions = [self actionsForSelectedDossiers];
		// Normalement il n'y a toujours qu'une seule action principale.
		NSArray *mainActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.possibleMainActions]];
		self.secondaryActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.possibleMainActions]];
		
		NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:3];
		
		[toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			  target:self
																			  action:nil]];
		
		if (self.secondaryActions.count > 0) {
			UIButton *moreActions = [UIButton buttonWithType:UIButtonTypeCustom];
			moreActions.backgroundColor = [UIColor darkGrayColor];
			moreActions.frame = CGRectMake(0.0f, 0.0f, 90.0f, CGRectGetHeight(self.navigationController.toolbar.bounds));
			
			[moreActions setTitle:@"Plus"
						 forState:UIControlStateNormal];
			
			[moreActions setTitleColor:[UIColor whiteColor]
							  forState:UIControlStateNormal];
			
			[moreActions addTarget:self
							action:@selector(showMoreActions:)
				  forControlEvents:UIControlEventTouchUpInside];
			
			moreBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:moreActions];
			[toolbarItems addObject:moreBarButtonItem];
		}
		
		if (mainActions.count > 0) {
			self.mainAction = [mainActions objectAtIndex:0];
			UIButton *mainAction = [UIButton buttonWithType:UIButtonTypeCustom];
			mainAction.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
			//mainAction.titleLabel.font = [UIFont systemFontOfSize:14.0f];
			mainAction.backgroundColor = [UIColor darkGreenColor];
			mainAction.frame = CGRectMake(0.0f, 0.0f, 90.0f, CGRectGetHeight(self.navigationController.toolbar.bounds));
			[mainAction setTitle:[ADLAPIHelper actionNameForAction:self.mainAction] forState:UIControlStateNormal];
			[mainAction setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
			[mainAction addTarget:self action:@selector(mainActionPressed) forControlEvents:UIControlEventTouchUpInside];
			
			[toolbarItems addObject:[[UIBarButtonItem alloc] initWithCustomView:mainAction]];
		}
		[self.navigationController.toolbar setItems:[NSArray arrayWithArray:toolbarItems] animated:YES];
	}
	else {
		[self.navigationController setToolbarHidden:YES animated:YES];
		moreBarButtonItem = nil;
	}
}


-(void)mainActionPressed {
	if (self.mainAction) {
		@try {
			[self performSegueWithIdentifier:self.mainAction sender:self];
		}
		@catch (NSException *exception) {
			[[[UIAlertView alloc] initWithTitle:@"Action impossible"
										message:@"Vous ne pouvez pas effectuer cette action sur tablette."
									   delegate:nil
							  cancelButtonTitle:@"Fermer"
							  otherButtonTitles: nil] show];
		}
		@finally {}
	}
}


-(void)showMoreActions:(id) sender {
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Traitement par lot"
															 delegate:self
													cancelButtonTitle:nil
											   destructiveButtonTitle:nil
													otherButtonTitles:nil];
	
	for (NSString *action in self.secondaryActions) {
		NSString *actionName = [ADLAPIHelper actionNameForAction:action];
		[actionSheet addButtonWithTitle:actionName];
	}
	[actionSheet addButtonWithTitle:@"Annuler"];
	
	
	// Find the barButtonItem
	UIBarButtonItem *moreItem = nil;
	
	for (UIBarButtonItem *item in self.navigationController.toolbar.items) {
		if ([(UIView*)sender isDescendantOfView:item.customView]) {
			moreItem = item;
			break;
		}
	}
	if (moreItem) {
		[actionSheet showFromBarButtonItem:moreItem
								  animated:YES];
	}
	//[(UIView*) sender convertRect:((UIView*)sender).frame toView:self.view];
	else {
		[actionSheet showFromRect:((UIView*)sender).frame
						   inView:self.view
						 animated:YES];
	}
}


-(IBAction)loadNextResultsPage:(id)sender {
	_currentPage += 1;
	[self loadDossiersWithPage:_currentPage];
}


-(NSArray*)actionsForSelectedDossiers {
	NSMutableArray* actions;
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		for (ADLResponseDossier* dossier in _selectedDossiersArray) {
			NSArray* dossierActions = [ADLAPIHelper actionsForADLResponseDossier:dossier];
			
			if (!actions) { // the first dossier only
				actions = [NSMutableArray arrayWithArray:dossierActions];
			}
			else {
				[actions filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", dossierActions]];
			}
		}
	}
	else {
		for (NSDictionary* dossier in self.selectedDossiersArray) {
			NSArray* dossierActions = [ADLAPIHelper actionsForDossier:dossier];
			
			if (!actions) { // the first dossier only
				actions = [NSMutableArray arrayWithArray:dossierActions];
			}
			else {
				[actions filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", dossierActions]];
			}
		}
	}
	
	return actions;
}


#pragma mark - UITableViewDatasource


-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section {
	
	//if (tableView == self.searchDisplayController.searchResultsTableView) {
	return [_filteredDossiersArray count];
	//} else {
	//    return [self.dossiersArray count];
	//}
}


-(UITableViewCell*)tableView:(UITableView *)tableView
	   cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"dossierCell";
	
	RGFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	cell.delegate = self;
	
	NSString *dossierTitre;
	NSString *dossierType;
	NSString *dossierSousType;
	NSString *dossierActionDemandee;
	NSDate *dossierDate = nil;
	bool dossierPossibleSignature;
	bool dossierPossibleArchive;
	bool dossierPossibleViser;
	
	if ([[ADLRestClient getRestApiVersion] intValue] == 3) {
		ADLResponseDossiers *dossier = [_filteredDossiersArray objectAtIndex:[indexPath row]];
		dossierTitre = dossier.title;
		dossierType = dossier.type;
		dossierSousType = dossier.sousType;
		dossierActionDemandee = dossier.actionDemandee;
		dossierPossibleSignature = dossier.actions && [dossier.actions containsObject:@"SIGNATURE"];
		dossierPossibleArchive = dossier.actions && [dossier.actions containsObject:@"ARCHIVAGE"];
		dossierPossibleViser = dossier.actions && [dossier.actions containsObject:@"VISA"];
		
		if ([dossier.dateLimite longLongValue] != 0)
			dossierDate = [NSDate dateWithTimeIntervalSince1970:(dossier.dateLimite.longLongValue/1000)];
		else
			dossierDate = nil;
	}
	else {
		NSDictionary *dossier = [self.filteredDossiersArray objectAtIndex:[indexPath row]];
		dossierTitre = [dossier objectForKey:@"titre"];
		dossierType = [dossier objectForKey:@"type"];
		dossierSousType = [dossier objectForKey:@"sousType"];
		dossierActionDemandee = [dossier objectForKey:@"actionDemandee"];
		dossierPossibleSignature = [[[dossier objectForKey:@"actions"] objectForKey:@"sign"] boolValue];
		dossierPossibleArchive = [[[dossier objectForKey:@"actions"] objectForKey:@"archive"] boolValue];
		dossierPossibleViser = [[[dossier objectForKey:@"actions"] objectForKey:@"visa"] boolValue];
		
		//Adrien TODO : check v2
		if(dossierPossibleViser)
			NSLog(@"Adrien visa V2 :%@", dossier);
		
		NSString *dateLimite = [dossier objectForKey:@"dateLimite"];
		
		if (dateLimite != nil) {
			ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
			//[formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss'Z'"];
			dossierDate = [formatter dateFromString:dateLimite];
		}
	}
	
	// Adapter
	
	cell.dossierTitleLabel.text = dossierTitre;
	cell.typologyLabel.text = [NSString stringWithFormat:@"%@ / %@", dossierType, dossierSousType];
	
	if (dossierPossibleSignature || dossierPossibleArchive || dossierPossibleViser) {
		NSString *actionName = [ADLAPIHelper actionNameForAction:dossierActionDemandee];
		cell.validateButton.hidden = NO;
		[cell.validateButton setTitle:actionName forState:UIControlStateNormal];
	}
	else {
		cell.validateButton.hidden = YES;
	}
	
	
	if (dossierDate != nil) {
		
		NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
		[outputFormatter setDateStyle:NSDateFormatterShortStyle];
		[outputFormatter setTimeStyle:NSDateFormatterNoStyle];
		//[outputFormatter setDateFormat:@"dd MMM"];
		
		NSString *fdate = [outputFormatter stringFromDate:dossierDate];
		cell.retardBadge.badgeText = fdate;
		[cell.retardBadge autoBadgeSizeWithString: fdate];
		[cell.retardBadge setHidden:NO];
	}
	else {
		[cell.retardBadge setHidden:YES];
	}
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		ADLResponseDossier *dossier = [self.filteredDossiersArray objectAtIndex:[indexPath row]];
		cell.switchButton.on = [self.selectedDossiersArray containsObject:dossier];
	}
	else {
		NSDictionary *dossier = [self.filteredDossiersArray objectAtIndex:[indexPath row]];
		cell.switchButton.on = [self.selectedDossiersArray containsObject:dossier];
	}
	
	return cell;
}


#pragma mark - Wall delegate


-(void)didEndWithRequestAnswer:(NSDictionary *)answer {
	NSArray *dossiers = API_GETDOSSIERHEADERS_GET_DOSSIERS(answer);
	[self.refreshControl endRefreshing];
	HIDE_HUD
	[self getDossierDidEndWithSuccess:dossiers];
}


-(void)didEndWithUnAuthorizedAccess {
	[self.refreshControl endRefreshing];
	HIDE_HUD
}


-(void)didEndWithUnReachableNetwork {
	[self.refreshControl endRefreshing];
	HIDE_HUD
}


-(void)filterDossiersForSearchText:(NSString*) searchText {
	
	if (searchText && (searchText.length > 0)) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K CONTAINS[cd] %@)", @"title", searchText]; // TODO Adrien : test V2
		NSArray *array = [self.dossiersArray filteredArrayUsingPredicate:predicate];
		self.filteredDossiersArray = array;	}
	else {
		self.filteredDossiersArray = [NSArray arrayWithArray:self.dossiersArray];
	}
	
}


-(void)getDossierDidEndWithSuccess:(NSArray*)dossiers {
	
	if (_currentPage > 0)
		[self.dossiersArray removeLastObject];
	else
		[self.dossiersArray removeAllObjects];
	
	// Switch v2/v3
	
	bool isLoaded = (dossiers.count) > 0;
	bool isVersion2 = isLoaded && [dossiers[0] isKindOfClass:[NSDictionary class]];
	
	/* manualy filters the locked files out */
	if ([dossiers count] > 0) {
		NSMutableArray *lockedDossiers = [NSMutableArray arrayWithCapacity:[dossiers count]];
		
		if (isVersion2) {
			for (NSDictionary *dossier in dossiers) {
				
				NSNumber *locked = [dossier objectForKey:@"locked"];
				
				if (locked && [locked isEqualToNumber:[NSNumber numberWithBool:YES]])
					[lockedDossiers addObject:dossier];
			}
		}
		else {
			for (ADLResponseDossiers *dossier in dossiers)
				if (dossier && dossier.locked)
					[lockedDossiers addObject:dossier];
		}
		
		if ([lockedDossiers count] > 0) {
			dossiers = [NSMutableArray arrayWithArray:dossiers];
			[(NSMutableArray*)dossiers removeObjectsInArray:lockedDossiers];
		}
	}
	
	[_dossiersArray addObjectsFromArray:dossiers];
	_loadMoreButton.hidden = (dossiers.count < 15);
	_filteredDossiersArray = [NSArray arrayWithArray:_dossiersArray];
	_selectedDossiersArray = [NSMutableArray arrayWithCapacity:_dossiersArray.count];
	
	[((UITableView*)[self view]) reloadData];
	
	HIDE_HUD
}


#pragma mark - UISearchBarDelegate protocol implementation


-(void)searchBar:(UISearchBar *)searchBar
   textDidChange:(NSString *)searchText {
	
	[self filterDossiersForSearchText:searchText];
	[self.tableView reloadData];
}


#pragma mark - FilterDelegate protocol implementation


-(void)shouldReload:(NSDictionary *)filter {
	[ADLSingletonState sharedSingletonState].currentFilter = [NSMutableDictionary dictionaryWithDictionary: filter];
	[[NSNotificationCenter defaultCenter] postNotificationName:kFilterChanged object:nil];
	[self refresh];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue
				sender:(id)sender {
	
	if ([segue.identifier isEqualToString:@"filterSegue"]) {
		((ADLFilterViewController *) segue.destinationViewController).delegate = self;
	}
	else {
		NSMutableArray *selectedArray = [[NSMutableArray alloc] init];
		
		if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
			for (ADLResponseDossiers* responseDossiers in _selectedDossiersArray)
				[selectedArray addObject:responseDossiers.identifier];
		}
		else {
			// Adrien TODO : test
			selectedArray = [_selectedDossiersArray valueForKey:@"dossierRef"];
		}
		
		((RGWorkflowDialogViewController*) segue.destinationViewController).dossiersRef = selectedArray; // Adrien [_selectedDossiersArray valueForKey:@"dossierRef"];
		((RGWorkflowDialogViewController*) segue.destinationViewController).action = segue.identifier;
	}
}


-(void)viewDidUnload {
	[self setLoadMoreButton:nil];
	[super viewDidUnload];
}


#pragma mark UIActionSheetDelegate protocol implementation


-(void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex < self.secondaryActions.count) {
		NSString *action = [self.secondaryActions objectAtIndex:buttonIndex];
		@try {
			[self performSegueWithIdentifier:action
									  sender:self];
		}
		@catch (NSException *exception) {
			[[[UIAlertView alloc] initWithTitle:@"Action impossible"
										message:@"Vous ne pouvez pas effectuer cette action sur tablette."
									   delegate:nil
							  cancelButtonTitle:@"Fermer"
							  otherButtonTitles:nil]
			 show];
		}
		@finally {}
	}
}


#pragma mark RGFileCellDelegate protocol implementation


-(void)cell:(RGFileCell *)cell didSelectAtIndexPath:(NSIndexPath *)indexPath {
	
	// Cancel event if reselection of a cell
	
	BOOL hasSomeSelected = (cell.tableView.indexPathForSelectedRow != nil);
	BOOL areSameCell = (cell.tableView.indexPathForSelectedRow.row == indexPath.row);
	
	if (hasSomeSelected && areSameCell)
		return;
	
	// Cancel event if no internet
	
//	if (![DeviceUtils isConnectedToInternet]) {
//
//		[DeviceUtils logError:[NSError errorWithDomain:NSCocoaErrorDomain
//														 code:kCFURLErrorNotConnectedToInternet
//													 userInfo:nil]];
//		[cell flickerSelection];
//		return;
//	}
	
	// v2/v3 compatibility
	
	bool isLoaded = (self.filteredDossiersArray.count > 0) || (self.dossiersArray.count > 0);
	bool isFilteredVersion2 = isLoaded && [self.filteredDossiersArray[0] isKindOfClass:[NSDictionary class]];
	bool isDossierVersion2 = isLoaded && [self.dossiersArray[0] isKindOfClass:[NSDictionary class]];
	bool isVersion2 = isLoaded && (isFilteredVersion2 && isDossierVersion2);
	
	NSString *dossierRef;
	
	if (isLoaded && isVersion2) {
		if(cell.tableView == self.searchDisplayController.searchResultsTableView)
			dossierRef = [[self.filteredDossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
		else
			dossierRef = [[self.dossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
	}
	else {
		if(cell.tableView == self.searchDisplayController.searchResultsTableView)
			dossierRef = ((ADLResponseDossiers *)[self.filteredDossiersArray objectAtIndex:indexPath.row]).identifier;
		else
			dossierRef = ((ADLResponseDossiers *) [self.dossiersArray objectAtIndex:indexPath.row]).identifier;
	}
	
	//
	
	[cell.tableView deselectRowAtIndexPath:[cell.tableView indexPathForSelectedRow] animated:NO];
	[cell.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	[cell setSelected:YES animated:NO];
	
	[[ADLSingletonState sharedSingletonState] setDossierCourant:dossierRef];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kDossierSelected object:dossierRef];
}


-(void)cell:(RGFileCell *)cell didCheckAtIndexPath:(NSIndexPath *)indexPath {
	[self.swipedCell hideMenuOptions];
	//[cell.tableView deselectRowAtIndexPath:[cell.tableView indexPathForSelectedRow] animated:YES];
	NSDictionary * dossier;
	//if(cell.tableView == self.searchDisplayController.searchResultsTableView) {
	dossier = [self.filteredDossiersArray objectAtIndex:indexPath.row];
	//}
	//else {
	//    dossier = [self.dossiersArray objectAtIndex:indexPath.row];
	//}
	
	if ([self.selectedDossiersArray containsObject:dossier])
	{
		[self.selectedDossiersArray removeObject:dossier];
		if (self.selectedDossiersArray.count == 0) {
			[self setInBatchMode:NO];
		}
	}
	else
	{
		[self.selectedDossiersArray addObject:dossier];
		if (self.selectedDossiersArray.count == 1) {
			[self setInBatchMode:YES];
		}
	}
	[self updateToolBar];
	
}


-(void)cell:(RGFileCell*)cell didTouchSecondaryButtonAtIndexPath:(NSIndexPath*) indexPath {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		ADLResponseDossier *dossier = [self.dossiersArray objectAtIndex:indexPath.row];
		_secondaryActions = [[ADLAPIHelper actionsForADLResponseDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", _possibleMainActions]];
		
		self.selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
		[self showMoreActions:cell];
	}
	else {
		NSDictionary *dossier = [self.dossiersArray objectAtIndex:indexPath.row];
		_secondaryActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", _possibleMainActions]];
		_selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
		[self showMoreActions:cell];
	}
}


-(void)cell:(RGFileCell*)cell didTouchMainButtonAtIndexPath:(NSIndexPath*) indexPath {
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		ADLResponseDossier *dossier = [_dossiersArray objectAtIndex:indexPath.row];
		NSArray *mainActions = [[ADLAPIHelper actionsForADLResponseDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", _possibleMainActions]];
		if (mainActions.count > 0) {
			_mainAction = [mainActions objectAtIndex:0];
			_selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
			[self mainActionPressed];
		}
	}
	else {
		NSDictionary *dossier = [_dossiersArray objectAtIndex:indexPath.row];
		NSArray *mainActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.possibleMainActions]];
		if (mainActions.count > 0) {
			_mainAction = [mainActions objectAtIndex:0];
			_selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
			[self mainActionPressed];
		}
	}
}


-(BOOL)canSelectCell:(RGFileCell *)cell {
	return YES;
}


-(BOOL)canSwipeCell:(RGFileCell *)cell {
	return (!self.isInBatchMode && (_swipedCell == cell));
}


-(void)willSwipeCell:(RGFileCell *)cell {
	if (cell != self.swipedCell) {
		[self.swipedCell hideMenuOptions];
	}
	self.swipedCell = cell;
}


-(void)willSelectCell:(RGFileCell *)cell {
	if (self.swipedCell) {
		[self.swipedCell hideMenuOptions];
		self.swipedCell = nil;
	}
}


#pragma mark - LGViewHUDDelegate protocol implementation


-(void)shallDismissHUD:(LGViewHUD*)hud {
	HIDE_HUD
}


@end
