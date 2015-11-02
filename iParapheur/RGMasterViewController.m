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
//  RGDetailViewController.m
//  iParapheur
//
//

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
	_bureauxArray = [NSMutableArray new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onLoginPopupDismissed:)
												 name:@"loginPopupDismiss"
											   object:nil];
	
	self.navigationController.navigationBar.tintColor = [UIColor darkBlueColor];
	self.refreshControl = [UIRefreshControl new];
	self.refreshControl.tintColor = [UIColor selectedCellGreyColor];
	
	[self.refreshControl addTarget:self
							action:@selector(loadBureaux)
				  forControlEvents:UIControlEventValueChanged];

	_settingsButton.target = self;
	_settingsButton.action = @selector(onSettingsButtonClicked:);
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
			UIViewController * splashscreenViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RGSplashscreenViewControllerId"];
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
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
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
							 [[ADLRestClient sharedManager] setRestApiVersion:[NSNumber numberWithInt:-1]];
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
		
		NSDate *currentDate = [NSDate new];
		
		NSDateFormatter *dateFormatter = [NSDateFormatter new];
		dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Europe/London"];
		[dateFormatter setDateFormat:@"H"];
		
		NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
		numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
		NSNumber *hour = [numberFormatter numberFromString:[dateFormatter stringFromDate:currentDate]];
		
		[DeviceUtils logInfoMessage:@"L'application est actuellement liée au parapheur de démonstration."];
		
		if (([hour integerValue] > 23) || ([hour integerValue] < 7))
			[DeviceUtils logWarningMessage:@"Le parapheur de démonstration peut être soumis à des déconnexions, entre minuit et 7h du matin (heure de Paris)."];
	}
	@catch (NSException *e) { }
}


- (void)updateVersionNumberInSettings {
	NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"version_preference"];
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
					[strongSelf.tableView setContentOffset:CGPointMake(0, strongSelf.tableView.contentOffset.y-strongSelf.refreshControl.frame.size.height)
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


- (void)settingsButtonWithWarning:(BOOL) warning {

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
	
	if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue ] >= 3) {
		__weak typeof(self) weakSelf = self;
		[_restClient getBureaux:^(NSArray *bureaux) {
							__strong typeof(weakSelf) strongSelf = weakSelf;
							if (strongSelf) {
								[strongSelf setBureauxArray:bureaux];
								strongSelf.loading = NO;
								[strongSelf.refreshControl endRefreshing];
								[(UITableView*)([strongSelf view]) reloadData];
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


#pragma mark - Wall impl


- (void)didEndWithRequestAnswer:(NSDictionary*)answer{
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
		
		[self setBureauxArray:array];
		
		// add a cast to get rid of the warning since the view is indeed a table view it respons to reloadData
		[(UITableView*)([self view]) reloadData];
		
		[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
		
	}
	
	//storing ticket ? lacks the host and login information
	//we should add it into the request process ?
	
}


- (void)didEndWithUnReachableNetwork{
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
	RGDeskCustomTableViewCell *cell = (RGDeskCustomTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	cell.todoBadge.badgeStyle.badgeInsetColor = [UIColor darkBlueColor];
	cell.lateBadge.badgeStyle.badgeInsetColor = [UIColor darkRedColor];
	
	bool isLoaded = _bureauxArray.count > 0;
	bool isVersion2 = isLoaded && [_bureauxArray[0] isKindOfClass:[NSDictionary class]];
	
	NSString *bureauName;
	NSString *bureauEnRetard;
	NSString *bureauATraiter;
	
	if (isLoaded && isVersion2) {
		NSDictionary *bureau = _bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau[@"name"];
		bureauEnRetard = [NSString stringWithFormat:@"%@", bureau[@"en_retard"]];
		bureauATraiter = [NSString stringWithFormat:@"%@", bureau[@"a_traiter"]];
	}
	else {
		ADLResponseBureau *bureau = _bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau.name;
		bureauEnRetard = bureau.enRetard.stringValue;
		bureauATraiter = bureau.aTraiter.stringValue;
	}
	
	cell.bureauNameLabel.text = bureauName;
		
	cell.todoBadge.badgeText = bureauATraiter;
	[cell.todoBadge autoBadgeSizeWithString:bureauATraiter];
	
	cell.lateBadge.badgeText = bureauEnRetard;
	[[cell lateBadge] autoBadgeSizeWithString:bureauEnRetard];
	
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
		NSDictionary *bureau = _bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau[@"name"];
		bureauNodeRef = bureau[@"nodeRef"];
	}
	else {
		ADLResponseBureau *bureau = _bureauxArray[(NSUInteger) indexPath.row];
		bureauName = bureau.name;
		bureauNodeRef = bureau.nodeRef;
	}

	NSLog(@"Selected Desk = %@", bureauNodeRef);

	RGDeskViewController *controller = (RGDeskViewController *) [self.storyboard instantiateViewControllerWithIdentifier:@"DeskViewController"];
	[controller setDeskRef:bureauNodeRef];

	[self.navigationController pushViewController:controller
	                                     animated:YES];

	controller.navigationItem.title = bureauName;

	[ADLSingletonState sharedSingletonState].bureauCourant = bureauNodeRef;
}


@end
