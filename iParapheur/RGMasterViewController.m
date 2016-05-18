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
#import "ADLCredentialVault.h"
#import "RGDeskCustomTableViewCell.h"
#import "ADLNotifications.h"
#import "UIColor+CustomColors.h"
#import "ADLRequester.h"
#import "SCNetworkReachability.h"
#import "ADLResponseBureau.h"
#import "DeviceUtils.h"


@interface RGMasterViewController ()

@end


@implementation RGMasterViewController


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGDossieMasterViewController");

	[self updateVersionNumberInSettings];

	_firstLaunch = TRUE;
	_bureauxArray = [[NSMutableArray alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(onLoginPopupDismissed:)
	                                             name:@"loginPopupDismiss"
	                                           object:nil];

	self.navigationController.navigationBar.tintColor = [UIColor darkBlueColor];

	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.tintColor = [UIColor selectedCellGreyColor];

	[self.refreshControl addTarget:self
	                        action:@selector(loadBureaux)
	              forControlEvents:UIControlEventValueChanged];
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:YES];
}


- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];

	// Settings check

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

	NSString *urlSettings = [preferences objectForKey:@"settings_server_url"];
	NSString *loginSettings = [preferences objectForKey:@"settings_login"];
	NSString *passwordSettings = [preferences objectForKey:@"settings_password"];

	BOOL areSettingsSet = (urlSettings.length != 0) && (loginSettings.length != 0) && (passwordSettings.length != 0);
	[self settingsButtonWithWarning:!areSettingsSet];

	// First launch behavior.
	// We can't do it on viewDidLoad, we can display a modal view only here.

	if (_firstLaunch) {
		if (areSettingsSet) {
			[self initRestClient];
		}
		else {
			UIViewController *splashscreenViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RGSplashscreenViewControllerId"];
			[splashscreenViewController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
			[self presentViewController:splashscreenViewController
			                   animated:YES
			                 completion:nil];
		}
	}

	_firstLaunch = FALSE;
}


- (void)viewDidUnload {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
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

	_restClient = [ADLRestClient sharedManager];
	__weak typeof(self) weakSelf = self;
	[_restClient getApiLevel:^(NSNumber *versionNumber) {
		 __strong typeof(weakSelf) strongSelf = weakSelf;
		 if (strongSelf) {
			 [[ADLRestClient sharedManager] setRestApiVersion:versionNumber];
			 [strongSelf loadBureaux];
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
				                 [DeviceUtils logInfoMessage:@"Une connexion Internet est nécessaire au lancement de l'application."];
			                 }
			                 else {
				                 [DeviceUtils logError:error];
			                 }
		                 }
	                 }];

	[self initAlfrescoToken];
}


- (void)checkDemonstrationServer {

	if (![DeviceUtils isConnectedToDemoServer])
		return;

	@try {
		// Check UTC time, and warns for possible shutdowns

		NSDate *currentDate = [[NSDate alloc] init];

		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Europe/London"];
		dateFormatter.dateFormat = @"H";

		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		NSNumber *hour = [numberFormatter numberFromString:[dateFormatter stringFromDate:currentDate]];

		[DeviceUtils logInfoMessage:@"L'application est actuellement liée au parapheur de démonstration."];

		if ((hour.integerValue > 23) || (hour.integerValue < 7))
			[DeviceUtils logWarningMessage:@"Le parapheur de démonstration peut être soumis à des déconnexions, entre minuit et 7h du matin (heure de Paris)."];
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


- (void)settingsButtonWithWarning:(BOOL)warning {

	if (warning) {
		_settingsButton.image = [UIImage imageNamed:@"icon_login_add.png"];
		_settingsButton.tintColor = [UIColor darkRedColor];
	} else {
		_settingsButton.image = [UIImage imageNamed:@"icon_login.png"];
		_settingsButton.tintColor = [UIColor darkBlueColor];
	}
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
				                [DeviceUtils logError:error];
				                strongSelf.loading = NO;
				                [strongSelf.refreshControl endRefreshing];
				                [[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
			                }
		                }];
	}
	else if ([[ADLRestClient sharedManager] getRestApiVersion].intValue == 2) {
		API_GETBUREAUX();
	}
	else if ([[ADLRestClient sharedManager] getRestApiVersion].intValue == -1) {
		[self.refreshControl endRefreshing];
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
	}
	else if ([s isEqual:GETBUREAUX_API]) {
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


- (void)onLoginPopupDismissed:(NSNotification *)notification {

	// Popup response

	NSDictionary *userInfo = notification.userInfo;
	BOOL success = ((NSNumber *) userInfo[@"success"]).boolValue;

	// Settings values

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *urlSettings = [preferences objectForKey:@"settings_server_url"];
	NSString *loginSettings = [preferences objectForKey:@"settings_login"];
	NSString *passwordSettings = [preferences objectForKey:@"settings_password"];
	BOOL areSettingsSet = (urlSettings.length != 0) && (loginSettings.length != 0) && (passwordSettings.length != 0);

	// Check

	[self settingsButtonWithWarning:(!areSettingsSet && !success)];

	if (success || !areSettingsSet)
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

	static NSString *CellIdentifier = @"DeskCell";
	RGDeskCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.todoBadge.badgeStyle.badgeInsetColor = [UIColor darkBlueColor];
	cell.lateBadge.badgeStyle.badgeInsetColor = [UIColor darkRedColor];

	bool isLoaded = _bureauxArray.count > 0;
	bool isVersion2 = isLoaded && [_bureauxArray[0] isKindOfClass:[NSDictionary class]];

	NSString *bureauName;
	NSString *bureauEnRetard;
	NSString *bureauATraiter;

	if (isLoaded && isVersion2) {
		NSDictionary *bureau = self.bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau[@"name"];
		bureauEnRetard = [NSString stringWithFormat:@"%@", bureau[@"en_retard"]];
		bureauATraiter = [NSString stringWithFormat:@"%@", bureau[@"a_traiter"]];
	}
	else {
		ADLResponseBureau *bureau = self.bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau.name;
		bureauEnRetard = bureau.enRetard.stringValue;
		bureauATraiter = bureau.aTraiter.stringValue;
	}

	cell.bureauNameLabel.text = bureauName;

	cell.todoBadge.badgeText = bureauATraiter;
	[cell.todoBadge autoBadgeSizeWithString:bureauATraiter];

	cell.lateBadge.badgeText = bureauEnRetard;
	[cell.lateBadge autoBadgeSizeWithString:bureauEnRetard];

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

	bool isLoaded = _bureauxArray.count > 0;
	bool isVersion2 = isLoaded && [_bureauxArray[0] isKindOfClass:[NSDictionary class]];

	NSString *bureauName;
	NSString *bureauNodeRef;

	if (isLoaded && isVersion2) {
		NSDictionary *bureau = self.bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau[@"name"];
		bureauNodeRef = bureau[@"nodeRef"];
	}
	else {
		ADLResponseBureau *bureau = self.bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau.name;
		bureauNodeRef = bureau.nodeRef;
	}

	NSLog(@"Selected Desk = %@", bureauNodeRef);

	RGDeskViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeskViewController"];
	controller.deskRef = bureauNodeRef;

	[self.navigationController pushViewController:controller
	                                     animated:YES];

	controller.navigationItem.title = bureauName;
	[ADLSingletonState sharedSingletonState].bureauCourant = bureauNodeRef;
}


@end
