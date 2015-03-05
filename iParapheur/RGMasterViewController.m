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
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLCollectivityDef.h"
#import "LGViewHUD.h"
#import "ADLRestClient.h"
#import "Reachability.h"
#import "ADLResponseBureau.h"
#import "AJNotificationView.h"


@interface RGMasterViewController ()

@end

@implementation RGMasterViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : RGDossierDetailViewController");
		
	_bureauxArray = [[NSMutableArray alloc] init];
	
	self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0f
																		green:0.375f
																		 blue:0.75f
																		alpha:1.0f];
	self.refreshControl = [[UIRefreshControl alloc]init];
	self.refreshControl.tintColor = [UIColor colorWithRed:0.0f
													green:0.375f
													 blue:0.75f
													alpha:1.0f];
	[self.refreshControl addTarget:self
							action:@selector(loadBureaux)
				  forControlEvents:UIControlEventValueChanged];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:YES];
	
	if ([_bureauxArray count] == 0)
		API_LOGIN([[NSUserDefaults standardUserDefaults] stringForKey:@"login_preference"], [[NSUserDefaults standardUserDefaults] stringForKey:@"password_preference"]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kSelectBureauAppeared
														object:nil];
	
}


- (void)viewDidAppear:(BOOL)animated {
	
	// Settings check
	
	NSString *urlSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"url_preference"];
	NSString *loginSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"login_preference"];
	NSString *passwordSettings = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"password_preference"];
	bool areSettingsSet = (urlSettings.length != 0) && (loginSettings.length != 0) && (passwordSettings.length != 0);
	
	if (areSettingsSet) {
		[self initRestKit];
	}
	else {
		UIViewController * splashscreenViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RGSplashscreenViewControllerId"];
		[splashscreenViewController setModalTransitionStyle:UIModalPresentationPopover];
		[self presentViewController:splashscreenViewController
						   animated:YES
						 completion:nil];
	}
}


- (void)viewDidUnload {
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
		return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	else
		return YES;
}


#pragma mark - Private methods


- (void)initRestKit {
	
	_restClient = [[ADLRestClient alloc] init];
	
	[_restClient getApiLevel:^(NSNumber *versionNumber) {
						[self loadBureaux];
					 }
					 failure:^(NSError *error) {
						 UIViewController *rootController = [[[[UIApplication sharedApplication] windows] objectAtIndex:0] rootViewController];
						 [AJNotificationView showNoticeInView:[rootController view]
														 type:AJNotificationTypeRed
														title:[error localizedDescription]
											  linedBackground:AJLinedBackgroundTypeStatic
													hideAfter:2.5f];
					 }];
}


#pragma mark - Wall impl


- (void)didEndWithRequestAnswer:(NSDictionary*)answer{
	NSString *s = [answer objectForKey:@"_req"];
	_loading = NO;
	[self.refreshControl endRefreshing];
	
	if ([s isEqual:LOGIN_API]) {
		
		ADLCredentialVault *vault = [ADLCredentialVault sharedCredentialVault];
		ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
		[vault addCredentialForHost:[def host] andLogin:[def username] withTicket:API_LOGIN_GET_TICKET(answer)];

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


#pragma mark - Local methods


- (void)loadBureaux {
	
	[self.refreshControl beginRefreshing];
	//ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];
	
	if ([[ADLRestClient getRestApiVersion] intValue ] == 3) {
		[_restClient getBureaux:^(NSArray *bureaux) {
							[self setBureauxArray:bureaux];
							_loading = NO;
							[self.refreshControl endRefreshing];
							[(UITableView*)([self view]) reloadData];
							[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
			
						}
						failure:^(NSError *error) {
							NSLog(@"getBureaux error");
						}];
	}
	else {
		API_GETBUREAUX();
	}
}


#pragma mark - UITableDataSource delegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _bureauxArray.count;
}


/** Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier
	and querying for available reusable cells with dequeueReusableCellWithIdentifier:
	Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"DeskCell";
	RGDeskCustomTableViewCell *cell = (RGDeskCustomTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	[cell.todoBadge.badgeStyle setBadgeInsetColor:[UIColor blueColor]];
	
	bool isLoaded = _bureauxArray.count > 0;
	bool isVersion2 = isLoaded && [_bureauxArray[0] isKindOfClass:[NSDictionary class]];
	
	NSString *bureauName;
	NSString *bureauEnRetard;
	NSString *bureauATraiter;
	
	if (isLoaded && isVersion2) {
		NSDictionary *bureau = [[self bureauxArray] objectAtIndex:[indexPath row]];
		bureauName = [bureau objectForKey:@"name"];
		bureauEnRetard =  [NSString stringWithFormat:@"%@", [bureau objectForKey:@"en_retard"]];
		bureauATraiter =  [NSString stringWithFormat:@"%@", [bureau objectForKey:@"a_traiter"]];
	}
	else {
		ADLResponseBureau *bureau = [[self bureauxArray] objectAtIndex:[indexPath row]];
		bureauName = bureau.name;
		bureauEnRetard = [bureau.enRetard stringValue];
		bureauATraiter = [bureau.aTraiter stringValue];
	}
	
	[[cell bureauNameLabel] setText:bureauName];
		
	[[cell todoBadge] setBadgeText:bureauATraiter];
	[[cell todoBadge] autoBadgeSizeWithString:bureauATraiter];
	
	[[cell lateBadge] setBadgeText:bureauEnRetard];
	[[cell lateBadge] autoBadgeSizeWithString:bureauEnRetard];
	
	return cell;
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	bool isLoaded = _bureauxArray.count > 0;
	bool isVersion2 = isLoaded && [_bureauxArray[0] isKindOfClass:[NSDictionary class]];
	
	NSString *bureauName;
	NSString *bureauNodeRef;
	
	if (isLoaded && isVersion2) {
		NSDictionary *bureau = [[self bureauxArray] objectAtIndex:[indexPath row]];
		bureauName = [bureau objectForKey:@"name"];
		bureauNodeRef = [bureau objectForKey:@"nodeRef"];
	}
	else {
		ADLResponseBureau *bureau = [[self bureauxArray] objectAtIndex:[indexPath row]];
		bureauName = bureau.name;
		bureauNodeRef = bureau.nodeRef;
	}
	
	NSLog(@"Selected Desk = %@", bureauNodeRef);
	
	RGDeskViewController *controller = [[self storyboard] instantiateViewControllerWithIdentifier:@"DeskViewController"];
	[controller setDeskRef:bureauNodeRef];
	[[self navigationController] pushViewController:controller animated:YES];
	[[controller navigationItem] setTitle:bureauName];
	
	[[ADLSingletonState sharedSingletonState] setBureauCourant:bureauNodeRef];
}


@end
