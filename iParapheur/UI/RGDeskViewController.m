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

#import "RGDeskViewController.h"
#import "RGWorkflowDialogViewController.h"
#import "ADLNotifications.h"
#import "ADLRequester.h"
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

	self.navigationItem.backBarButtonItem.tintColor = ColorUtils.DarkBlue;
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
}


- (void)refresh {

	[self.refreshControl beginRefreshing];
	[self loadDossiersWithPage:0];
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


- (void)loadDossiersWithPage:(int)page {

	NSDictionary *currentFilter = [ADLSingletonState sharedSingletonState].currentFilter;

	if (currentFilter != nil) {

		NSMutableArray *types = [NSMutableArray new];
		for (NSString *type in currentFilter[@"types"])
			[types addObject:@{@"ph:typeMetier" : type}];

		NSMutableArray *sousTypes = [NSMutableArray new];
		for (NSString *sousType in currentFilter[@"sousTypes"])
			[sousTypes addObject:@{@"ph:soustypeMetier" : sousType}];

		NSDictionary *titre = @{@"or" : @[@{@"cm:title" : [NSString stringWithFormat:@"*%@*", currentFilter[@"titre"]]}]};
		NSDictionary *filtersDictionary = @{@"and" : @[@{@"or" : types}, @{@"or" : sousTypes}, titre]};

		// Send request

		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {

			// Stringify JSON filter

			NSError *error;
			NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filtersDictionary
			                                                   options:0
			                                                     error:&error];

			NSString *jsonString = nil;
			if (jsonData)
				jsonString = [[NSString alloc] initWithData:jsonData
				                                   encoding:NSUTF8StringEncoding];

			// API3 request

			__weak typeof(self) weakSelf = self;

			[_restClient getDossiers:_deskRef
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
					                 [ViewUtils logErrorMessage:[StringUtils getErrorMessage:error]
					                                      title:nil
					                             viewController:nil];
					                 [strongSelf.refreshControl endRefreshing];
					                 HIDE_HUD
				                 }
			                 }];
		}
		else {
			API_GETDOSSIERHEADERS_FILTERED(self.deskRef, @(page), @"15", currentFilter[@"banette"], filtersDictionary);
		}
	}
	else {
		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
			__weak typeof(self) weakSelf = self;
			[_restClient getDossiers:self.deskRef
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
					                 [ViewUtils logErrorMessage:[StringUtils getErrorMessage:error]
					                                      title:nil
					                             viewController:nil];
					                 [strongSelf.refreshControl endRefreshing];
					                 HIDE_HUD
				                 }
			                 }];
		}
		else {
			API_GETDOSSIERHEADERS(self.deskRef, @(page), @"15");
		}
	}
}


- (void)viewWillDisappear:(BOOL)animated {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {

	[self setLoadMoreButton:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super didReceiveMemoryWarning];
}


#pragma Private methods


- (void)updateToolBar {

	if (_selectedDossiersArray.count != 0) {

		if (self.navigationController.toolbarHidden)
			[self.navigationController setToolbarHidden:NO
			                                   animated:YES];

		NSMutableArray *actions = [Dossier filterActions:_selectedDossiersArray];
		NSArray *mainActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", _possibleMainActions]];
		_secondaryActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", _possibleMainActions]];

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
			_mainAction = mainActions[0];

			UIButton *mainAction = [UIButton buttonWithType:UIButtonTypeCustom];
			mainAction.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
			//mainAction.titleLabel.font = [UIFont systemFontOfSize:14.0f];
			mainAction.backgroundColor = [ColorUtils DarkGreen];
			mainAction.frame = CGRectMake(0.0f, 0.0f, 90.0f, CGRectGetHeight(self.navigationController.toolbar.bounds));
			[mainAction setTitle:[ADLAPIHelper actionNameForAction:_mainAction]
			            forState:UIControlStateNormal];
			[mainAction setTitleColor:[UIColor whiteColor]
			                 forState:UIControlStateNormal];
			[mainAction addTarget:self
			               action:@selector(mainActionPressed)
			     forControlEvents:UIControlEventTouchUpInside];

			[toolbarItems addObject:[[UIBarButtonItem alloc] initWithCustomView:mainAction]];
		}
		[self.navigationController.toolbar setItems:[NSArray arrayWithArray:toolbarItems]
		                                   animated:YES];
	}
	else {
		[self.navigationController setToolbarHidden:YES
		                                   animated:YES];
		moreBarButtonItem = nil;
	}
}


- (void)updateListWithoutFlickering {

	for (FolderListCell *cell in self.tableView.visibleCells) {
		cell.checkboxHandlerView.hidden = (_selectedDossiersArray.count == 0);
		cell.selectionStyle = (_selectedDossiersArray.count == 0) ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
	}
}


- (void)mainActionPressed {

	if (self.mainAction) {
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


- (void)showMoreActions:(id)sender {

	if ([UIAlertController class]) { // iOS8

		// Create Popup Controller

		UIAlertController *actionController = [UIAlertController alertControllerWithTitle:@"Traitement par lot"
		                                                                          message:nil
		                                                                   preferredStyle:UIAlertControllerStyleActionSheet];

		[actionController setModalPresentationStyle:UIModalPresentationPopover];

		// Create Popup actions

		for (NSString *action in _secondaryActions) {

			NSString *actionName = [ADLAPIHelper actionNameForAction:action];
			UIAlertAction *action = [UIAlertAction actionWithTitle:actionName
			                                                 style:UIAlertActionStyleDefault
			                                               handler:^(UIAlertAction *alertAction) {
				                                               [self clickOnSecondaryAction:alertAction.title];
			                                               }];
			[actionController addAction:action];
		}

		UIAlertAction *actionAnnuler = [UIAlertAction actionWithTitle:@"Annuler"
		                                                        style:UIAlertActionStyleDefault
		                                                      handler:nil];
		[actionController addAction:actionAnnuler];

		// Find the barButtonItem

		UIBarButtonItem *moreItem = nil;

		for (UIBarButtonItem *item in self.navigationController.toolbar.items) {
			if ([(UIView *) sender isDescendantOfView:item.customView]) {
				moreItem = item;
				break;
			}
		}

		// Display the popup

		[self presentViewController:actionController
		                   animated:YES
		                 completion:nil];

		UIPopoverPresentationController *popPresenter = [actionController popoverPresentationController];

		if (moreItem) {
			popPresenter.sourceView = moreItem.customView;
			popPresenter.sourceRect = moreItem.customView.bounds;
		}
		else {
			popPresenter.sourceView = (UIView *) sender;
			popPresenter.sourceRect = ((UIView *) sender).bounds;
		}
	}
	else { // iOS7

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
			if ([(UIView *) sender isDescendantOfView:item.customView]) {
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
			[actionSheet showFromRect:((UIView *) sender).frame
			                   inView:self.view
			                 animated:YES];
		}
	}
}


- (IBAction)loadNextResultsPage:(id)sender {

	_currentPage += 1;
	[self loadDossiersWithPage:_currentPage];
}


#pragma mark - UITableViewDatasource


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	//if (tableView == self.searchDisplayController.searchResultsTableView) {
	return [_filteredDossiersArray count];
	//} else {
	//    return [self.dossiersArray count];
	//}
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

	bool isSelected = [_selectedDossiersArray containsObject:dossier];
	cell.checkOffImage.hidden = isSelected;
	cell.checkOnImage.hidden = !isSelected;

	// Action dot

//	BOOL canSign = [dossier.unwrappedActions containsObject:@"SIGNATURE"];
//	BOOL canArchive = [dossier.unwrappedActions containsObject:@"ARCHIVAGE"];
//	BOOL canVisa = [dossier.unwrappedActions containsObject:@"VISA"];
//	BOOL canTdt = [dossier.unwrappedActions containsObject:@"TDT"];
//
//	if (canSign)
//		cell.dot.tintColor = ColorUtils.Salmon;
//	else if (canTdt)
//		cell.dot.tintColor = ColorUtils.Flora;
//	else if (canArchive)
//		cell.dot.tintColor = ColorUtils.Sky;
//	else if (canVisa)
//		cell.dot.tintColor = ColorUtils.Lime;
//	else
	cell.dot.tintColor = ColorUtils.LightGrey;

	// Adapter

	cell.titleLabel.text = dossier.unwrappedTitle;
	cell.typologyLabel.text = [NSString stringWithFormat:@"%@ / %@",
	                                                     dossier.unwrappedType,
	                                                     dossier.unwrappedSubType];

	// Date

	NSDate *dossierDate = nil;

	if (dossier.unwrappedLimitDate.longLongValue != 0)
		dossierDate = [NSDate dateWithTimeIntervalSince1970:(dossier.unwrappedLimitDate.longLongValue / 1000)];

	cell.limitDateLabel.hidden = (dossierDate == nil);

	if (dossierDate != nil) {
		BOOL isLate = ([dossierDate compare:[NSDate new]] == NSOrderedAscending);

		NSDateFormatter *outputFormatter = [NSDateFormatter new];
		outputFormatter.dateStyle = NSDateFormatterShortStyle;
		outputFormatter.timeStyle = NSDateFormatterNoStyle;

		NSString *datePrint = [outputFormatter stringFromDate:dossierDate];
		cell.limitDateLabel.text = [NSString stringWithFormat:@"avant le %@",
		                                                      datePrint];
		cell.limitDateLabel.textColor = isLate ? ColorUtils.Salmon : ColorUtils.BlueGreySeparator;
	}

	return cell;
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSLog(@"Adrien - didSelectRowAtIndexPath");

	// Get target Dossier

	FolderListCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	Dossier *dossierClicked;

	if (self.tableView == self.searchDisplayController.searchResultsTableView)
		dossierClicked = ((Dossier *) _filteredDossiersArray[(NSUInteger) indexPath.row]);
	else
		dossierClicked = ((Dossier *) _dossiersArray[(NSUInteger) indexPath.row]);

	// Selection mode

	if (_selectedDossiersArray.count != 0) {

		if ([_selectedDossiersArray containsObject:dossierClicked]) {
			[_selectedDossiersArray removeObject:dossierClicked];
			cell.checkOnImage.hidden = YES;
			cell.checkOffImage.hidden = NO;
		}
		else {
			[_selectedDossiersArray addObject:dossierClicked];
			cell.checkOnImage.hidden = NO;
			cell.checkOffImage.hidden = YES;
		}

		if (_selectedDossiersArray.count == 0) {
			[self updateListWithoutFlickering];
			[self updateToolBar];
		}

		return;
	}

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


- (IBAction)tableViewDidLongPress:(UILongPressGestureRecognizer*) sender {
	NSLog(@"Adrien - tableViewDidLongPress");

	if (sender.state != UIGestureRecognizerStateBegan)
		return;

	CGPoint indexPathPoint = [sender locationInView:self.tableView];
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:indexPathPoint];

	// Long press on table view but not on a row

	if (indexPath == nil)
		return;

	// Default case

	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
	NSLog(@"Long press on table view at section %d row %d", indexPath.section, indexPath.row);

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

	[self updateListWithoutFlickering];
	[self updateToolBar];
}


#pragma mark - Wall delegate


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSArray *dossiers = API_GETDOSSIERHEADERS_GET_DOSSIERS(answer);
	[self.refreshControl endRefreshing];
	HIDE_HUD
	[self getDossierDidEndWithSuccess:dossiers];
}


- (void)didEndWithUnAuthorizedAccess {

	[self.refreshControl endRefreshing];
	HIDE_HUD
}


- (void)didEndWithUnReachableNetwork {

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
	}
	else {
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
	_selectedDossiersArray = [NSMutableArray arrayWithCapacity:_dossiersArray.count];

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


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	if ([segue.identifier isEqualToString:@"filterSegue"]) {
		((ADLFilterViewController *) segue.destinationViewController).delegate = self;
	}
	else {
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


#pragma mark UIActionSheetDelegate protocol implementation


/**
 * iOS7 response of ActionSheet events.
 * The UIActionSheetDelegate isn't used anymore in iOS8.
 */
- (void) actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (buttonIndex < self.secondaryActions.count) {
		NSString *action = self.secondaryActions[(NSUInteger) buttonIndex];
		[self clickOnSecondaryAction:action];
	}
}


- (void)clickOnSecondaryAction:(NSString *)actionName {

	@try {
		[self performSegueWithIdentifier:actionName
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
}


#pragma mark RGFileCellDelegate protocol implementation


- (void)       cell:(RGFileCell *)cell
didCheckAtIndexPath:(NSIndexPath *)indexPath {

	NSLog(@"Adrien - didCheckAtIndexPath");
//
//	[self.swipedCell hideMenuOptions];
//
//	Dossier *dossier = _filteredDossiersArray[(NSUInteger) indexPath.row];
//
//	if ([_selectedDossiersArray containsObject:dossier])
//		[_selectedDossiersArray removeObject:dossier];
//	else
//		[_selectedDossiersArray addObject:dossier];
//
//	_inBatchMode = _selectedDossiersArray.count != 0;
//	[self updateToolBar];
}


- (void)                      cell:(RGFileCell *)cell
didTouchSecondaryButtonAtIndexPath:(NSIndexPath *)indexPath {

	NSLog(@"Adrien - didTouchSecondaryButtonAtIndexPath");

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		// Adrien
//		Dossier *dossier = _dossiersArray[(NSUInteger) indexPath.row];
//		_secondaryActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",
//		                                                                                                                                      _possibleMainActions]];
//
//		_selectedDossiersArray = @[dossier].mutableCopy;
//		[self showMoreActions:cell];
	}
}


- (void)                 cell:(RGFileCell *)cell
didTouchMainButtonAtIndexPath:(NSIndexPath *)indexPath {

	NSLog(@"Adrien - didTouchMainButtonAtIndexPath");

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		// Adrien
//		Dossier *dossier = _dossiersArray[(NSUInteger) indexPath.row];
//		NSArray *mainActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@",
//		                                                                                                                                         _possibleMainActions]];
//		if (mainActions.count > 0) {
//			_mainAction = mainActions[0];
//			_selectedDossiersArray = @[dossier].mutableCopy;
//			[self mainActionPressed];
//		}
	}
}


- (BOOL)canSelectCell:(RGFileCell *)cell {

	return YES;
}


- (BOOL)canSwipeCell:(RGFileCell *)cell {
	return (_selectedDossiersArray.count == 0) && (_swipedCell == cell);
}


- (void)willSwipeCell:(RGFileCell *)cell {

	if (cell != self.swipedCell) {
		[self.swipedCell hideMenuOptions];
	}
	self.swipedCell = cell;
}


- (void)willSelectCell:(RGFileCell *)cell {

	if (self.swipedCell) {
		[self.swipedCell hideMenuOptions];
		self.swipedCell = nil;
	}
}


#pragma mark - LGViewHUDDelegate protocol implementation


- (void)shallDismissHUD:(LGViewHUD *)hud {

	HIDE_HUD
}


#pragma mark - LGViewHUDDelegate protocol implementation


@end
