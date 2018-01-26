/*
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
#import <SCNetworkReachability/SCNetworkStatus.h>
#import "RGMasterViewController.h"
#import "ADLCredentialVault.h"
#import "iParapheur-Swift.h"
#import "ADLRequester.h"
#import "StringUtils.h"
#import "DeviceUtils.h"
#import <SCNetworkReachability/SCNetworkReachability.h>
#import "iParapheur-Swift.h"


@interface RGMasterViewController ()

@end


@implementation RGMasterViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGMasterViewController");

	// Patch Accounts
	[ModelsDataController loadManagedObjectContext];

	[self updateVersionNumberInSettings];

	_firstLaunch = TRUE;
	_bureauxArray = [NSMutableArray new];

	[NSNotificationCenter.defaultCenter addObserver:self
	                                       selector:@selector(onModelsCoreDataLoaded:)
	                                           name:ModelsDataController.NotificationModelsDataControllerLoaded
	                                         object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
	                                       selector:@selector(onAccountSelected:)
	                                           name:AccountSelectionController.NotifSelected
	                                         object:nil];

	[NSNotificationCenter.defaultCenter addObserver:self
	                                       selector:@selector(onAccountSelected:)
	                                           name:FirstLoginPopupController.NotifDismiss
	                                         object:nil];

	self.refreshControl = [UIRefreshControl new];
	self.refreshControl.tintColor = [ColorUtils SelectedCellGrey];

	[self.refreshControl addTarget:self
	                        action:@selector(loadBureaux)
	              forControlEvents:UIControlEventValueChanged];

	_settingsButton.target = self;
	_settingsButton.action = @selector(onSettingsButtonClicked:);

	_accountButton.target = self;
	_accountButton.action = @selector(onAccountButtonClicked:);
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super didReceiveMemoryWarning];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	else
		return YES;
}


#pragma mark - Private methods


- (void)initRestClient {

	[self checkDemonstrationServer];
	[ADLRestClient.sharedManager resetClient];

	_restClient = ADLRestClient.sharedManager;

	__weak typeof(self) weakSelf = self;
	[_restClient getApiLevel:^(NSNumber *versionNumber) {
						 __strong typeof(weakSelf) strongSelf = weakSelf;
						 if (strongSelf) {
							 [ADLRestClient.sharedManager setRestApiVersion:versionNumber];
							 [strongSelf loadBureaux];
						 }
					 }
	                 failure:^(NSError *error) {
		                 __strong typeof(weakSelf) strongSelf = weakSelf;
		                 if (strongSelf) {
			                 [ADLRestClient.sharedManager setRestApiVersion:@(-1)];
			                 [strongSelf.refreshControl endRefreshing];
			                 strongSelf.bureauxArray = @[];
			                 [(UITableView *) strongSelf.view reloadData];

			                 // New test when network retrieved
			                 if (error.code == kCFURLErrorNotConnectedToInternet) {
				                 [strongSelf setNewConnectionTryOnNetworkRetrieved];
				                 [ViewUtils logInfoWithMessage:@"Une connexion Internet est nécessaire au lancement de l'application."
														 title:nil];
			                 } else {
				                 [ViewUtils logErrorWithMessage:[StringUtils getErrorMessage:error]
				                                          title:nil];
			                 }
		                 }
	                 }];
}


- (void)checkDemonstrationServer {

	if (![DeviceUtils isConnectedToDemoAccount])
		return;

	@try {
		// Check UTC time, and warns for possible shutdowns	
		NSDate *currentDate = [NSDate new];

		NSDateFormatter *dateFormatter = [NSDateFormatter new];
		dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Europe/London"];
		[dateFormatter setDateFormat:@"H"];

		NSNumberFormatter *numberFormatter = [NSNumberFormatter new];

		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		NSNumber *hour = [numberFormatter numberFromString:[dateFormatter stringFromDate:currentDate]];

		[ViewUtils logInfoWithMessage:@"L'application est actuellement liée au parapheur de démonstration."
								title:nil];

		if ((hour.integerValue > 23) || (hour.integerValue < 7))
			[ViewUtils logWarningWithMessage:@"Le parapheur de démonstration peut être soumis à des déconnexions, entre minuit et 7h du matin (heure de Paris)."
									   title:nil];
	}
	@catch (NSException *e) {}
}


- (void)updateVersionNumberInSettings {

	NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
	[[NSUserDefaults standardUserDefaults] setObject:version
	                                          forKey:@"version_preference"];
}


- (void)setNewConnectionTryOnNetworkRetrieved {

	__weak typeof(self) weakSelf = self;
	[SCNetworkReachability host:@"www.apple.com"
	         reachabilityStatus:^(SCNetworkStatus status) {

		         __strong typeof(weakSelf) strongSelf = weakSelf;
		         if (strongSelf) {
			         switch (status) {
				         case SCNetworkStatusReachableViaWiFi:
				         case SCNetworkStatusReachableViaCellular:
					         [strongSelf.refreshControl beginRefreshing];
					         [strongSelf.tableView setContentOffset:CGPointMake(0, strongSelf.tableView.contentOffset.y - strongSelf.refreshControl.frame.size.height)
					                                       animated:YES];
					         [strongSelf initRestClient];
					         break;

				         case SCNetworkStatusNotReachable:
					         break;
			         }
		         }
	         }];
}


- (void)loadBureaux {

	[self.refreshControl beginRefreshing];

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue != -1) {
		__weak typeof(self) weakSelf = self;
		[_restClient getBureaux:^(NSArray *bureaux) {
							 __strong typeof(weakSelf) strongSelf = weakSelf;
							 if (strongSelf) {
								 strongSelf.bureauxArray = bureaux;
								 strongSelf.loading = NO;
								 [strongSelf.refreshControl endRefreshing];
								 [(UITableView *) strongSelf.view reloadData];
								 [LGViewHUD.defaultHUD hideWithAnimation:HUDAnimationNone];
							 }
						 }
		                failure:^(NSError *error) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                strongSelf.bureauxArray = @[];
				                strongSelf.loading = NO;
				                [strongSelf.refreshControl endRefreshing];
				                [(UITableView *) strongSelf.view reloadData];
				                [LGViewHUD.defaultHUD hideWithAnimation:HUDAnimationNone];
				                [ViewUtils logErrorWithMessage:[StringUtils getErrorMessage:error]
				                                         title:nil];
			                }
		                }];
	} else {
		[self.refreshControl endRefreshing];
	}
}


- (void)refreshAccountIcon:(BOOL)isAccountSet {

	_accountButton.tintColor = isAccountSet ? [ColorUtils Aqua] : [ColorUtils Salmon];
}


#pragma mark - Button Listeners


- (void)onSettingsButtonClicked:(id)sender {
	// TODO : Direct call to login popup, on no-account set

	// Displays secondary Settings.storyboard
	// TODO : Switch to easier linked Storyboard
	// (When iOS9 will be the oldest supported version)

	UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Settings"
	                                             bundle:nil];

	UIViewController *vc = sb.instantiateInitialViewController;
	vc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

	[self presentViewController:vc
	                   animated:YES
	                 completion:NULL];
}


- (void)onAccountButtonClicked:(id)sender {

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *selectedAccountId = [preferences objectForKey:[Account PreferencesKeySelectedAccount]];
	BOOL areSettingsSet = (selectedAccountId.length > 1);

	if (areSettingsSet) {
		[self performSegueWithIdentifier:AccountSelectionController.Segue
		                          sender:self];
	} else {
		[self performSegueWithIdentifier:FirstLoginPopupController.Segue
		                          sender:self];
	}
}


#pragma mark - Wall impl


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSString *s = answer[@"_req"];
	_loading = NO;
	[self.refreshControl endRefreshing];

	if ([s isEqual:LOGIN_API]) {

		ADLCredentialVault *vault = [ADLCredentialVault sharedCredentialVault];
		ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];

		[vault addCredentialForHost:def.host
		                   andLogin:def.username
		                 withTicket:API_LOGIN_GET_TICKET(answer)];

		[self loadBureaux];
	} else if ([s isEqual:GETBUREAUX_API]) {
		NSArray *array = API_GETBUREAUX_GET_BUREAUX(answer);

		_bureauxArray = array;

		// add a cast to get rid of the warning since the view is indeed a table view it respons to reloadData
		[(UITableView *) self.view reloadData];

		[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];

	}

	//storing ticket ? lacks the host and login information
	//we should add it into the request process ?

}


- (void)didEndWithUnReachableNetwork {

	[self.refreshControl endRefreshing];
}


- (void)didEndWithUnAuthorizedAccess {

	[self.refreshControl endRefreshing];
}


#pragma mark - NotificationCenter messages


- (void)onModelsCoreDataLoaded:(NSNotification *)notification {

	[ModelsDataController cleanupAccounts];

	// Settings check

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *selectedAccountId = [preferences objectForKey:[Account PreferencesKeySelectedAccount]];

	BOOL areSettingsSet = (selectedAccountId.length > 1);
	[self refreshAccountIcon:areSettingsSet];

	// First launch behavior.
	// We can't do it on viewDidLoad, we can display a modal view only here.

	if (_firstLaunch) {
		if (areSettingsSet) {
			[self initRestClient];
		} else {
			[self performSegueWithIdentifier:FirstLoginPopupController.Segue
			                          sender:self];
		}
	}

	_firstLaunch = FALSE;
}


- (void)onAccountSelected:(NSNotification *)notification {

	// Popup response

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *selectedAccountId = [preferences objectForKey:[Account PreferencesKeySelectedAccount]];

	BOOL areSettingsSet = (selectedAccountId.length > 1);

	// Check

	[self refreshAccountIcon:areSettingsSet];
	[self initRestClient];
}


#pragma mark - UITableDataSource delegate


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	if (_bureauxArray.count == 0) {
		tableView.backgroundView = [DeskListEmptyView instanceFromNib];
		tableView.tableFooterView.hidden = true;
	}

	else {
		tableView.backgroundView = nil;
		tableView.tableFooterView.hidden = false;
	}

	return _bureauxArray.count;
}


/**
 * Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier
 * and querying for available reusable cells with dequeueReusableCellWithIdentifier:
 * Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
 */
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	DeskListCell *cell = [tableView dequeueReusableCellWithIdentifier:DeskListCell.CellId];
	Bureau *bureau = (Bureau *) _bureauxArray[(NSUInteger) indexPath.row];

	// Folders to do
	
	if (bureau.aTraiter == 0)
		cell.foldersToDo.text = @"Aucun dossier à traiter";
	else if (bureau.aTraiter == 1)
		cell.foldersToDo.text = @"1 dossier à traiter";
	else
		cell.foldersToDo.text = [NSString stringWithFormat:@"%ld dossiers à traiter", (long) bureau.aTraiter];

	// Delegations

    if (bureau.dossiersDelegues > 0)
        cell.foldersToDo.text = [NSString stringWithFormat:@"%@, %d en délégation", cell.foldersToDo.text, bureau.dossiersDelegues];

	// Late Folders
	
	cell.lateFolders.hidden = (bureau.enRetard == 0);
	
	if (bureau.aTraiter == 1)
		cell.lateFolders.text = @"1 dossier en retard";
	else
		cell.lateFolders.text = [NSString stringWithFormat:@"%ld dossiers en retard", (long) bureau.enRetard];
	
	//

	cell.title.text = bureau.name;
	cell.disclosureIndicator.image = [cell.disclosureIndicator.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	cell.dot.image = [cell.dot.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	
	return cell;
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	// Cancel event if no internet

//	if (![DeviceUtils isConnectedToInternet]) {
//		
//		[tableView deselectRowAtIndexPath:indexPath
//								 animated:YES];
//		
//		[DeviceUtils logError:[NSError errorWithDomain:NSCocoaErrorDomain
//														 code:kCFURLErrorNotConnectedToInternet
//													 userInfo:nil]];
//		return;
//	}

	// Call Desk view

	Bureau *bureau = self.bureauxArray[(NSUInteger) indexPath.row];
	NSLog(@"Selected Desk = %@", bureau.nodeRef);

	RGDeskViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeskViewController"];

	[self.navigationController pushViewController:controller
	                                     animated:YES];

	controller.desk = bureau;
	controller.navigationItem.title = bureau.name;
	[ADLSingletonState sharedSingletonState].bureauCourant = bureau.nodeRef;
}


@end
