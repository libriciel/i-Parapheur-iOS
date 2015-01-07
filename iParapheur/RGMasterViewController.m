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

@interface RGMasterViewController ()

@end

@implementation RGMasterViewController


/*
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}*/


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib
    _deskArray = [[NSMutableArray alloc] init];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    self.refreshControl.tintColor = [UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f];
    [self.refreshControl addTarget:self action:@selector(loadBureaux) forControlEvents:UIControlEventValueChanged];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    if ([_deskArray count] == 0) {
        API_LOGIN([[NSUserDefaults standardUserDefaults] stringForKey:@"login_preference"], [[NSUserDefaults standardUserDefaults] stringForKey:@"password_preference"]);
                  /*
        ADLRequester *requester = [ADLRequester sharedRequester];
        [requester setDelegate:self];
             
        NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:[[NSUserDefaults standardUserDefaults] stringForKey:@"login_preference"], @"username", [[NSUserDefaults standardUserDefaults] stringForKey:@"password_preference"], @"password", nil];
                
        [requester request:LOGIN_API andArgs:args];*/
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectBureauAppeared object:nil];

}

- (void)loadBureaux
{
    [self.refreshControl beginRefreshing];
    //ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];

    API_GETBUREAUX();
    
   
    /*if (displayHUD == NO) {
        LGViewHUD *hud = [LGViewHUD defaultHUD];
        hud.image=[UIImage imageNamed:@"rounded-checkmark.png"];
        hud.topText=@"";
        hud.bottomText=@"Chargement ...";
        hud.activityIndicatorOn=YES;
        [hud showInView:self.view];
    }*/
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
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

        [self setDeskArray:array];
          
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

#pragma UITableDataSource delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_deskArray == nil) {
        return 0;
    }
    else {
        return [_deskArray count];
    }
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"DeskCell";
    
    RGDeskCustomTableViewCell *cell = (RGDeskCustomTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    NSDictionary *bureau = [ [self deskArray] objectAtIndex:[indexPath row]];
    NSLog(@"%@", [bureau objectForKey:@"name"]);
    [[cell bureauNameLabel] setText:[bureau objectForKey:@"name"]];
   
    NSNumber *a_traiter = [bureau objectForKey:@"a_traiter"];
    
    [[cell todoBadge] setBadgeText:[a_traiter stringValue]];
    [[cell todoBadge] autoBadgeSizeWithString: [a_traiter stringValue]];
    [cell.todoBadge.badgeStyle setBadgeInsetColor:[UIColor blueColor]];
    
    NSNumber *en_retard = [bureau objectForKey:@"en_retard"];
    
    [[cell lateBadge] setBadgeText:[en_retard stringValue]];
    [[cell lateBadge] autoBadgeSizeWithString: [en_retard stringValue]];
    return cell;
    
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *bureau = [[self deskArray] objectAtIndex:[indexPath row]];
    NSLog(@"Selected Desk = %@", [bureau objectForKey:@"nodeRef"]);
    
    RGDeskViewController *controller = [[self storyboard] instantiateViewControllerWithIdentifier:@"DeskViewController"];
    [controller setDeskRef:[bureau objectForKey:@"nodeRef"]];
    [[self navigationController] pushViewController:controller animated:YES];
    
    [[controller navigationItem] setTitle:[bureau objectForKey:@"name"]];
    
    //[[self navigationController] setTitle:[bureau objectForKey:@"name"]];
    
    [[ADLSingletonState sharedSingletonState] setBureauCourant:[bureau objectForKey:@"nodeRef"]];

}

@end
