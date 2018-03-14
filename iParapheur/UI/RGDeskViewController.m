/*
 * Contributors : SKROBS (2012)
 * Copyright 2012-2017, Libriciel SCOP.
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
#import "RGDeskViewController.h"
#import "RGWorkflowDialogViewController.h"
#import "ADLNotifications.h"
#import "iParapheur-Swift.h"
#import "StringUtils.h"


@interface RGDeskViewController () {
	int _currentPage;
	UIBarButtonItem *moreBarButtonItem;
}

@property(nonatomic, weak) RGFileCell *swipedCell;
@property(nonatomic, retain, readonly) NSArray *possibleMainActions;
@property(nonatomic, retain, readonly) NSArray *actionsWithoutAnnotation;
@property(nonatomic, retain) NSString *mainAction;
@property(nonatomic, retain) NSArray *secondaryActions;

@end


@implementation RGDeskViewController


#pragma mark - UIViewController delegate


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGDeskViewController");

	self.navigationItem.backBarButtonItem.tintColor = ColorUtils.Aqua;
	self.refreshControl = [UIRefreshControl new];
	self.refreshControl.tintColor = ColorUtils.SelectedCellGrey;

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

	_restClient = [ADLRestClient sharedManager];
	_selectedDossiersArray = [NSMutableArray new];
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:YES];

	_currentPage = 0;
	_dossiersArray = [NSMutableArray new];
	_possibleMainActions = @[@"VISA", @"SIGNATURE", @"TDT", @"MAILSEC", @"ARCHIVER"];
	_actionsWithoutAnnotation = @[@"RECUPERER", @"SUPPRIMER", @"SECRETARIAT"];

	SHOW_HUD
	[self loadDossiersWithPage:_currentPage];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	if ([segue.identifier isEqualToString:@"filterSegue"]) {
		((ADLFilterViewController *) segue.destinationViewController).delegate = self;
	} else {
		NSMutableArray *selectedArray = [NSMutableArray new];

		for (Dossier *dossier in _selectedDossiersArray)
			[selectedArray addObject:dossier];

		// Paper signature is just a Visa, actually

		BOOL isPaperSign = YES;

		for (Dossier *dossier in selectedArray)
			if (!dossier.unwrappedIsSignPapier)
				isPaperSign = NO;

		// Launch popup

		RGWorkflowDialogViewController *workflowDialogViewController = segue.destinationViewController;
		workflowDialogViewController.dossiers = selectedArray;
		workflowDialogViewController.action = segue.identifier;
		workflowDialogViewController.isPaperSign = isPaperSign;
	}
}


- (void)didReceiveMemoryWarning {

	_loadMoreButton = nil;
	[NSNotificationCenter.defaultCenter removeObserver:self];

	[super didReceiveMemoryWarning];
}


- (void)viewWillDisappear:(BOOL)animated {

	[NSNotificationCenter.defaultCenter removeObserver:self];
	[super viewWillDisappear:animated];
}


#pragma Private methods


- (void)updateToolBar {

	if (_selectedDossiersArray.count != 0) {

		NSMutableArray *actions = [Dossier filterActionsWithDossierList:_selectedDossiersArray];
		NSArray *mainActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@",
		                                                                                             _possibleMainActions]];
		_secondaryActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",
		                                                                                          _possibleMainActions]];

		if (_secondaryActions.count > 0) {
			_bottomBarNegativeButton.target = self;
			_bottomBarNegativeButton.action = @selector(negativeButtonPressed:);
		}

		if (mainActions.count > 0) {
			_mainAction = mainActions[0];

			_bottomBarPositiveButton.enabled = YES;
			_bottomBarPositiveButton.tintColor = ColorUtils.Aqua;
			_bottomBarPositiveButton.title = [StringUtils actionNameForAction:_mainAction];
			_bottomBarPositiveButton.target = self;
			_bottomBarPositiveButton.action = @selector(positiveButtonPressed:);
		} else {
			_bottomBarPositiveButton.enabled = NO;
			_bottomBarPositiveButton.tintColor = [UIColor clearColor];
		}

		if (self.navigationController.toolbarHidden)
			[self.navigationController setToolbarHidden:NO
			                                   animated:YES];
	} else {
		[self.navigationController setToolbarHidden:YES
		                                   animated:YES];
		moreBarButtonItem = nil;
	}
}


- (void)updateSelectionMode {

	// Fetch cells and toggle dot/check

	for (FolderListCell *cell in self.tableView.visibleCells) {
		cell.checkboxHandlerView.hidden = (_selectedDossiersArray.count == 0);
		cell.dot.hidden = (_selectedDossiersArray.count != 0);
		cell.selectionStyle = (_selectedDossiersArray.count == 0) ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

		// Seems useless, but fixes a cell recycle UI problem,
		// when the selection mode is icon-exited and re-activated.
		if (_selectedDossiersArray.count == 0) {
			cell.checkOnImage.hidden = YES;
			cell.checkOffImage.hidden = NO;
		}
	}

	// Re-select previously selected cell

	if (_selectedDossiersArray.count == 0) {

		NSIndexPath *index = nil;
		NSString *selectedId = [ADLSingletonState sharedSingletonState].dossierCourantReference;
		NSArray *displayedDossierArray = (self.tableView == self.searchDisplayController.searchResultsTableView) ? _filteredDossiersArray : _dossiersArray;

		for (int i = 0; i < displayedDossierArray.count; i++)
			if ([((Dossier *) displayedDossierArray[(NSUInteger) i]).unwrappedId isEqualToString:selectedId])
				index = [NSIndexPath indexPathForRow:i
				                           inSection:0];

		if (index != nil) {
			[self.tableView selectRowAtIndexPath:index
			                            animated:NO
			                      scrollPosition:nil];
		}
	}

	// Update TopBar

	if (_selectedDossiersArray.count != 0) {

		UIBarButtonItem *exitButton = [UIBarButtonItem new];
		exitButton.title = @"Exit";
		exitButton.image = [UIImage imageNamed:@"ic_close_white.png"];
		exitButton.tintColor = ColorUtils.Aqua;
		exitButton.style = UIBarButtonItemStylePlain;
		exitButton.target = self;
		exitButton.action = @selector(exitSelection);

		self.navigationItem.leftBarButtonItem = exitButton;
		self.navigationItem.rightBarButtonItem.enabled = NO;
		self.navigationItem.rightBarButtonItem.tintColor = UIColor.clearColor;
		self.navigationItem.title = @"1 dossier sélectionné";
	} else {
		self.navigationItem.leftBarButtonItem = nil;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		self.navigationItem.rightBarButtonItem.tintColor = ColorUtils.Aqua;
		self.navigationItem.title = _desk.name;
	}
}


- (void)exitSelection {

	[_selectedDossiersArray removeAllObjects];
	[self updateSelectionMode];
	[self updateToolBar];
}


- (void)positiveButtonPressed:(id)sender {

	if (_mainAction) {
		@try {
			[self performSegueWithIdentifier:_mainAction
			                          sender:self];
		}
		@catch (NSException *exception) {
			[[[UIAlertView alloc] initWithTitle:@"Action impossible"
			                            message:@"Vous ne pouvez pas effectuer cette action sur tablette."
			                           delegate:nil
			                  cancelButtonTitle:@"Fermer"
			                  otherButtonTitles:nil] show];
		}
		@finally {}
	}
}


- (void)negativeButtonPressed:(id)sender {

	// Computing the negative action

	NSString *negativeAction = [Dossier getNegativeActionWithActions:_secondaryActions];

	// Starting popup

	if (negativeAction.length > 0) {
		@try {
			[self performSegueWithIdentifier:negativeAction
			                          sender:self];
		}
		@catch (NSException *exception) {
			[[[UIAlertView alloc] initWithTitle:@"Action impossible"
			                            message:@"Vous ne pouvez pas effectuer cette action sur tablette."
			                           delegate:nil
			                  cancelButtonTitle:@"Fermer"
			                  otherButtonTitles:nil] show];
		}
		@finally {}
	}
}


- (IBAction)loadNextResultsPage:(id)sender {

	_currentPage += 1;
	[self loadDossiersWithPage:_currentPage];
}


- (void)loadDossiersWithPage:(int)page {

	NSDictionary *currentFilter = ADLSingletonState.sharedSingletonState.currentFilter;

	if (currentFilter != nil) {

		NSMutableArray *types = NSMutableArray.new;
		for (NSString *type in currentFilter[@"types"])
			[types addObject:@{@"ph:typeMetier": type}];

		NSMutableArray *sousTypes = NSMutableArray.new;
		for (NSString *sousType in currentFilter[@"sousTypes"])
			[sousTypes addObject:@{@"ph:soustypeMetier": sousType}];

		NSDictionary *titre = @{@"or": @[@{@"cm:title": [NSString stringWithFormat:@"*%@*",
		                                                                           currentFilter[@"titre"]]}]};
		NSDictionary *filtersDictionary = @{@"and": @[@{@"or": types}, @{@"or": sousTypes}, titre]};

		// Send request

		// Stringify JSON filter

		NSError *error;
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtersDictionary
		                                                   options:0
		                                                     error:&error];

		NSString *jsonString = nil;
		if (jsonData)
			jsonString = [[NSString alloc] initWithData:jsonData
			                                   encoding:NSUTF8StringEncoding];

		// Request

		__weak typeof(self) weakSelf = self;

		[_restClient getDossiers:_desk.nodeRef
		                    page:page
		                    size:15
		                  filter:jsonString
		                 success:^(NSArray *dossiers) {
			                 __strong typeof(weakSelf) strongSelf = weakSelf;
			                 if (strongSelf) {
				                 NSLog(@"getDossiers success : %lu", (unsigned long) dossiers.count);
				                 [strongSelf.refreshControl endRefreshing];
				                 HIDE_HUD
				                 [strongSelf getDossierDidEndWithSuccess:dossiers];
			                 }
		                 }
		                 failure:^(NSError *getDossiersError) {
			                 __strong typeof(weakSelf) strongSelf = weakSelf;
			                 if (strongSelf) {
				                 [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
														  title:nil];
				                 [strongSelf.refreshControl endRefreshing];
				                 HIDE_HUD
			                 }
		                 }];
	} else {
		__weak typeof(self) weakSelf = self;
		[_restClient getDossiers:_desk.nodeRef
		                    page:page
		                    size:15
		                  filter:nil
		                 success:^(NSArray *dossiers) {
			                 __strong typeof(weakSelf) strongSelf = weakSelf;
			                 if (strongSelf) {
				                 NSLog(@"getDossiers success : %lu", (unsigned long) dossiers.count);
				                 [strongSelf.refreshControl endRefreshing];
				                 HIDE_HUD
				                 [strongSelf getDossierDidEndWithSuccess:dossiers];
			                 }
		                 }
		                 failure:^(NSError *error) {
			                 __strong typeof(weakSelf) strongSelf = weakSelf;
			                 if (strongSelf) {
				                 [ViewUtils logErrorWithMessage:[StringsUtils getMessageWithError:error]
				                                          title:nil];
				                 [strongSelf.refreshControl endRefreshing];
				                 HIDE_HUD
			                 }
		                 }];
	}
}


- (void)refresh {

	[self.refreshControl beginRefreshing];
	[self loadDossiersWithPage:0];
	[self exitSelection];
}


#pragma mark - UITableViewDatasource


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	if (_filteredDossiersArray.count == 0) {

		FolderListEmptyView *emptyView = [FolderListEmptyView instanceFromNib];
		emptyView.filterAlertLabel.hidden = (_dossiersArray.count > 0);

		tableView.backgroundView = emptyView;
		tableView.tableFooterView.hidden = true;
	} else {
		tableView.backgroundView = nil;
		tableView.tableFooterView.hidden = false;
	}

	return _filteredDossiersArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	FolderListCell *cell = [tableView dequeueReusableCellWithIdentifier:FolderListCell.CellIdentifier];
	Dossier *dossier = _filteredDossiersArray[(NSUInteger) indexPath.row];

	// UI fix

	if (cell.dot.image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
		cell.checkOffImage.image = [cell.checkOffImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		cell.checkOnImage.image = [cell.checkOnImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		cell.dot.image = [cell.dot.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	}

	// Selected state

	cell.selectionStyle = (_selectedDossiersArray.count == 0) ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
	cell.checkboxHandlerView.hidden = (_selectedDossiersArray.count == 0);
	cell.dot.hidden = (_selectedDossiersArray.count != 0);

	bool isSelected = [_selectedDossiersArray containsObject:dossier];
	cell.checkOffImage.hidden = isSelected;
	cell.checkOnImage.hidden = !isSelected;

	// Adapter

    cell.dot.tintColor = dossier.isDelegue ? ColorUtils.DarkPurple : ColorUtils.LightGrey;
	cell.titleLabel.text = dossier.unwrappedTitle;
	cell.typologyLabel.text = [NSString stringWithFormat:@"%@ / %@",
	                                                     dossier.unwrappedType,
	                                                     dossier.unwrappedSubType];

	// Date

	NSDate *dossierDate = nil;

	if (dossier.unwrappedLimitDate.longLongValue != 0)
		dossierDate = [NSDate dateWithTimeIntervalSince1970:dossier.unwrappedLimitDate.longLongValue / 1000];

	cell.limitDateLabel.hidden = (dossierDate == nil);

	if (dossierDate != nil) {
		BOOL isLate = ([dossierDate compare:[NSDate new]] == NSOrderedAscending);

		NSDateFormatter *outputFormatter = [NSDateFormatter new];
		outputFormatter.dateStyle = NSDateFormatterShortStyle;
		outputFormatter.timeStyle = NSDateFormatterNoStyle;

		NSString *datePrint = isLate ? @"en retard depuis le %@" : @"à rendre avant le %@";
		cell.limitDateLabel.text = [NSString stringWithFormat:datePrint,
		                                                      [outputFormatter stringFromDate:dossierDate]];

		cell.limitDateLabel.textColor = isLate ? ColorUtils.Salmon : ColorUtils.BlueGreySeparator;
	}

	return cell;
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// Get target Dossier

	FolderListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	Dossier *dossierClicked;

	if (self.tableView == self.searchDisplayController.searchResultsTableView)
		dossierClicked = ((Dossier *) _filteredDossiersArray[(NSUInteger) indexPath.row]);
	else
		dossierClicked = ((Dossier *) _dossiersArray[(NSUInteger) indexPath.row]);

	// Selection mode

	if (_selectedDossiersArray.count != 0) {

		// Update cell

		if ([_selectedDossiersArray containsObject:dossierClicked]) {
			[_selectedDossiersArray removeObject:dossierClicked];
			cell.checkOnImage.hidden = YES;
			cell.checkOffImage.hidden = NO;
		} else {
			[_selectedDossiersArray addObject:dossierClicked];
			cell.checkOnImage.hidden = NO;
			cell.checkOffImage.hidden = YES;
		}

		// Update UI

		if (_selectedDossiersArray.count == 1)
			self.navigationItem.title = @"1 dossier sélectionné";
		else
			self.navigationItem.title = [NSString stringWithFormat:@"%ld dossiers sélectionnés",
			                                                       _selectedDossiersArray.count];

		[self updateToolBar];

		if (_selectedDossiersArray.count == 0) {
			[self updateSelectionMode];
		}

		return;
	}

	// Re-selection

	if ([ADLSingletonState sharedSingletonState].dossierCourantReference == dossierClicked.unwrappedId)
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

	[ADLSingletonState sharedSingletonState].dossierCourantReference = dossierClicked.unwrappedId;

	[[NSNotificationCenter defaultCenter] postNotificationName:kDossierSelected
	                                                    object:dossierClicked.unwrappedId];
}


- (IBAction)tableViewDidLongPress:(UILongPressGestureRecognizer *)sender {

	if (sender.state != UIGestureRecognizerStateBegan)
		return;

	CGPoint indexPathPoint = [sender locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:indexPathPoint];

	// Long press on table view but not on a row

	if (indexPath == nil)
		return;

	// Default case

	// Those two lines are there to release the gesture event.
	// Otherwise, the long press is always called at every frame.
	// It looks like a very poor solution, it smells like a very poor solution,
	// but it's recommended by Apple there : https://developer.apple.com/videos/play/wwdc2014/235/
	// So... I guess it's the way to do it...
	sender.enabled = NO;
	sender.enabled = YES;
	// End of the gesture release event.

	// Refresh data

	Dossier *dossier = _filteredDossiersArray[(NSUInteger) indexPath.row];

	if ([_selectedDossiersArray containsObject:dossier])
		[_selectedDossiersArray removeObject:dossier];
	else
		[_selectedDossiersArray addObject:dossier];

	// Refresh UI

	[self.tableView reloadRowsAtIndexPaths:@[indexPath]
	                      withRowAnimation:nil];

	[self updateSelectionMode];
	[self updateToolBar];
}


#pragma mark - Wall delegate


- (void)didEndWithUnAuthorizedAccess {

	[self.refreshControl endRefreshing];
	HIDE_HUD
}

- (void)filterDossiersForSearchText:(NSString *)searchText {

	if (searchText && (searchText.length > 0)) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K CONTAINS[cd] %@)",
		                                                          @"title",
		                                                          searchText]; // TODO Adrien : test V2

		NSArray *array = [_dossiersArray filteredArrayUsingPredicate:predicate];
		_filteredDossiersArray = array;
	} else {
		_filteredDossiersArray = [NSArray arrayWithArray:_dossiersArray];
	}

}


- (void)getDossierDidEndWithSuccess:(NSArray *)dossiers {

	if (_currentPage > 0)
		[_dossiersArray removeLastObject];
	else
		[_dossiersArray removeAllObjects];

	/* manualy filters the locked files out */
	if (dossiers.count > 0) {
		NSMutableArray *lockedDossiers = [NSMutableArray arrayWithCapacity:dossiers.count];

		for (Dossier *dossier in dossiers)
			if (dossier && dossier.unwrappedIsLocked)
				[lockedDossiers addObject:dossier];

		if ([lockedDossiers count] > 0) {
			dossiers = [NSMutableArray arrayWithArray:dossiers];
			[(NSMutableArray *) dossiers removeObjectsInArray:lockedDossiers];
		}
	}

	[_dossiersArray addObjectsFromArray:dossiers];
	_loadMoreButton.hidden = (dossiers.count < 15);
	_filteredDossiersArray = [NSArray arrayWithArray:_dossiersArray];

	[((UITableView *) self.view) reloadData];

	HIDE_HUD
}


#pragma mark - UISearchBarDelegate protocol implementation


- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {

	[self filterDossiersForSearchText:searchText];
	[self.tableView reloadData];
}


#pragma mark - FilterDelegate protocol implementation


- (void)shouldReload:(NSDictionary *)filter {

	[ADLSingletonState sharedSingletonState].currentFilter = [NSMutableDictionary dictionaryWithDictionary:filter];
	[[NSNotificationCenter defaultCenter] postNotificationName:kFilterChanged
	                                                    object:nil];

	[self refresh];
}


#pragma mark - LGViewHUDDelegate protocol implementation


- (void)shallDismissHUD:(LGViewHUD *)hud {

	HIDE_HUD
}


@end
