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
#import <SCNetworkReachability/SCNetworkStatus.h>
#import "RGMasterViewController.h"
#import "ADLCredentialVault.h"
#import "ADLNotifications.h"
#import "iParapheur-Swift.h"
#import "ADLRequester.h"
#import "SCNetworkReachability.h"
#import "DeviceUtils.h"
#import "iParapheur-Swift.h"
#import "StringUtils.h"


@interface RGMasterViewController ()

@end


@implementation RGMasterViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGMasterViewController");

	// Patch Acounts
	// FIXME Adrien

	[ModelsDataController loadManagedObjectContext];

	//

	[self updateVersionNumberInSettings];

	_firstLaunch = TRUE;
	_bureauxArray = [NSMutableArray new];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(onLoginPopupDismissed:)
	                                             name:@"loginPopupDismiss"
	                                           object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(onModelsCoreDataLoaded:)
	                                             name:[ModelsDataController NotificationModelsDataControllerLoaded]
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
	[[ADLRestClient sharedManager] resetClient];

	_restClient = [ADLRestClient sharedManager];
	__weak typeof(self) weakSelf = self;
	[_restClient getApiLevel:^(NSNumber *versionNumber) {
		 __strong typeof(weakSelf) strongSelf = weakSelf;
		 if (strongSelf) {
			 [[ADLRestClient sharedManager] setRestApiVersion:versionNumber];
			 [strongSelf loadBureaux];
			 if (versionNumber.intValue == 2)
				 [self initAlfrescoToken];
		 }
	 }
	                 failure:^(NSError *error) {
		                 __strong typeof(weakSelf) strongSelf = weakSelf;
		                 if (strongSelf) {
			                 [[ADLRestClient sharedManager] setRestApiVersion:@(-1)];
			                 [strongSelf.refreshControl endRefreshing];

			                 // New test when network retrieved
			                 if (error.code == kCFURLErrorNotConnectedToInternet) {
				                 [strongSelf setNewConnectionTryOnNetworkRetrieved];
				                 [ViewUtils logInfoMessage:@"Une connexion Internet est nécessaire au lancement de l'application."
				                                     title:nil
				                            viewController:nil];
			                 } else {
				                 [ViewUtils logErrorMessage:[StringUtils getErrorMessage:error]
				                                      title:nil
				                             viewController:nil];
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

		[ViewUtils logInfoMessage:@"L'application est actuellement liée au parapheur de démonstration."
		                    title:nil
		           viewController:nil];

		if ((hour.integerValue > 23) || (hour.integerValue < 7))
			[ViewUtils logWarningMessage:@"Le parapheur de démonstration peut être soumis à des déconnexions, entre minuit et 7h du matin (heure de Paris)."
			                       title:nil
			              viewController:nil];
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


- (void)initAlfrescoToken {

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *login = [preferences objectForKey:@"settings_login"];
	NSString *password = [preferences objectForKey:@"settings_password"];

	if (login.length == 0) {
		login = @"bma";
		password = @"secret";
	}

	API_LOGIN(login, password);

	[[NSNotificationCenter defaultCenter] postNotificationName:kSelectBureauAppeared
	                                                    object:nil];
}


- (void)loadBureaux {

	[self.refreshControl beginRefreshing];

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getBureaux:^(NSArray *bureaux) {
			 __strong typeof(weakSelf) strongSelf = weakSelf;
			 if (strongSelf) {
				 strongSelf.bureauxArray = bureaux;
				 strongSelf.loading = NO;
				 [strongSelf.refreshControl endRefreshing];
				 [(UITableView *) strongSelf.view reloadData];
				 [[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
			 }
		 }
		                failure:^(NSError *error) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                [ViewUtils logErrorMessage:[StringUtils getErrorMessage:error]
				                                     title:nil
				                            viewController:nil];
				                strongSelf.loading = NO;
				                [strongSelf.refreshControl endRefreshing];
				                [[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
			                }
		                }];
	} else if ([[ADLRestClient sharedManager] getRestApiVersion].intValue == -1) {
		[self.refreshControl endRefreshing];
	}
}


- (void)refreshAccountIcon:(BOOL)isAccountSet {

	_accountButton.tintColor = isAccountSet ? [ColorUtils Aqua] : [ColorUtils Salmon];
}


- (void)displayAccountPopup {

	UIViewController *splashscreenViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RGSplashscreenViewControllerId"];
	[splashscreenViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
	[self presentViewController:splashscreenViewController
	                   animated:YES
	                 completion:nil];
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

//	if ([DeviceUtils isConnectedToDemoAccount]) {
//		[self displayAccountPopup];
//	} else {
//		// TODO : account list
		[self performSegueWithIdentifier:@"AccountListSegue"
		                          sender:self];
//	}
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

		self.bureauxArray = array;

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
			[self displayAccountPopup];
		}
	}

	_firstLaunch = FALSE;
}

- (void)onLoginPopupDismissed:(NSNotification *)notification {

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

	return _bureauxArray.count;
}


/**
 * Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier
 * and querying for available reusable cells with dequeueReusableCellWithIdentifier:
 * Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
 */
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	DeskListCell *cell = [tableView dequeueReusableCellWithIdentifier:[DeskListCell CellIdentifier]];
	Bureau *bureau = (Bureau *) _bureauxArray[(NSUInteger) indexPath.row];

	// Folders to do
	
	if (bureau.unwrappedATraiter.intValue == 0)
		cell.foldersToDo.text = @"Aucun dossier à traiter";
	else if (bureau.unwrappedATraiter.intValue == 1)
		cell.foldersToDo.text = @"1 dossier à traiter";
	else
		cell.foldersToDo.text = [NSString stringWithFormat:@"%d dossiers à traiter", bureau.unwrappedATraiter.intValue];
	
	// Late Folders
	
	cell.lateFolders.hidden = (bureau.unwrappedEnRetard.intValue == 0);
	
	if (bureau.unwrappedATraiter.intValue == 1)
		cell.lateFolders.text = @"1 dossier en retard";
	else
		cell.lateFolders.text = [NSString stringWithFormat:@"%d dossiers en retard", bureau.unwrappedEnRetard.intValue];
	
	//

	cell.title.text = bureau.unwrappedName;
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
	NSLog(@"Selected Desk = %@", bureau.unwrappedNodeRef);

	RGDeskViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeskViewController"];

	[self.navigationController pushViewController:controller
	                                     animated:YES];

	controller.desk = bureau;
	controller.navigationItem.title = bureau.unwrappedName;
	[ADLSingletonState sharedSingletonState].bureauCourant = bureau.unwrappedNodeRef;
}


@end
