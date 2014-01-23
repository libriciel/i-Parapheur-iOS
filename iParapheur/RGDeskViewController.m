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
#import "ADLFilterViewController.h"
#import "LGViewHUD.h"
#import "RGFileCell.h"
#import <ISO8601DateFormatter/ISO8601DateFormatter.h>
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "NSString+Contains.h"


@interface RGDeskViewController()
{
    int _currentPage;
}

@property (nonatomic, weak) RGFileCell* swipedCell;
@property (nonatomic, assign, getter = isInBatchMode) BOOL inBatchMode;

@end

@implementation RGDeskViewController

@synthesize inBatchMode = _inBatchMode;

#pragma mark - UIViewController delegate
-(void)viewDidLoad {
    [super viewDidLoad];
    //[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"TableViewPaperBackground.png"]]];

    [[self.navigationItem backBarButtonItem] setTintColor:[UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f]];
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl setTintColor:[UIColor colorWithRed:0.0f green:0.375f blue:0.75f alpha:1.0f]];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kDossierActionComplete object:nil];
    
    self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
    [self.searchDisplayController.searchResultsTableView registerClass:[RGFileCell class]forCellReuseIdentifier:@"dossierCell"];
    self.inBatchMode = NO;
    
}

-(void) refresh {
    [self.refreshControl beginRefreshing];
    [self loadDossiersWithPage:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    _currentPage = 0;
    self.dossiersArray = [NSMutableArray new];
    [self loadDossiersWithPage:_currentPage];
}


-(void) setInBatchMode:(BOOL) value {
    _inBatchMode = value;
    [self.navigationController setToolbarHidden:!_inBatchMode animated:YES];
}

-(void)loadDossiersWithPage:(int)page
{
    NSDictionary *currentFilter = [[ADLSingletonState sharedSingletonState] currentFilter];
    if (currentFilter != nil) {
        API_GETDOSSIERHEADERS_FILTERED(self.deskRef, [NSNumber numberWithInteger:page], @"15", currentFilter);
    }
    else {
        API_GETDOSSIERHEADERS(self.deskRef, [NSNumber numberWithInteger:page], @"15");
    }
}

- (IBAction)loadNextResultsPage:(id)sender {
    [self loadDossiersWithPage:++_currentPage]; 
}

-(NSArray*) actionsForSelectedDossiers {
    NSMutableArray* actions;
    for (NSDictionary* dossier in self.selectedDossiersArray) {
        NSArray* dossierActions = [self actionsForDossier:dossier];
        if (!actions) { // the first dossier only
            actions = [NSMutableArray arrayWithArray:dossierActions];
        }
        else {
            [actions filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", dossierActions]];
        }
    }
    return actions;
}

-(NSArray* ) actionsForDossier:(NSDictionary *) dossier {
    static BOOL _even = NO;
    _even = !_even;
    if (_even) {
        return [[NSArray alloc] initWithObjects:@"VISER", @"TDT", nil];
    }
    return [[NSArray alloc] initWithObjects:@"VISER", @"MAIL", @"REJETER", @"AVIS SUPPLEMENTAIRE", @"ENREGISTRER", @"RÉCUPÉRER", nil];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredDossiersArray count];
    } else {
        return [self.dossiersArray count];
    }
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"dossierCell";
    
    RGFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.delegate = self;
    
    NSDictionary *dossier;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        dossier = [self.filteredDossiersArray objectAtIndex:[indexPath row]];
    } else {
        dossier = [self.dossiersArray objectAtIndex:[indexPath row]];
    }
    
    // NSLog(@"%@", [dossier objectForKey:@"titre"]);
    
    cell.dossierTitleLabel.text = [dossier objectForKey:@"titre"];
    cell.typologyLabel.text = [NSString stringWithFormat:@"%@ / %@", [dossier objectForKey:@"type"], [dossier objectForKey:@"sousType"]];
    
    NSString *dateLimite = [dossier objectForKey:@"dateLimite"];
    if (dateLimite != nil) {
        ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
        //[formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss'Z'"];
        NSDate *dueDate = [formatter dateFromString:dateLimite];
        
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"dd MMM"];
        
        NSString *fdate = [outputFormatter stringFromDate:dueDate];
        cell.retardBadge.badgeText = fdate;
        [cell.retardBadge autoBadgeSizeWithString: [NSString stringWithFormat:@" %@ ", fdate]];
        [cell.retardBadge setHidden:NO];

    }
    else {
        [cell.retardBadge setHidden:YES];
    }
    cell.switchButton.on = [self.selectedDossiersArray containsObject:[dossier objectForKey:@"dossierRef"]];
    
    return cell;
}


#pragma mark UITableViewDelegate protocol implementation

-(void) cell:(RGFileCell *)cell didSelectAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.tableView deselectRowAtIndexPath:[cell.tableView indexPathForSelectedRow] animated:NO];
    
    [cell.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    if (!self.isInBatchMode) {
        
        NSString *dossierRef;
        
        if(cell.tableView == self.searchDisplayController.searchResultsTableView) {
            //        NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            dossierRef = [[self.filteredDossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
            //[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
        }
        else {
            //        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            dossierRef = [[self.dossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
        }
        [cell setSelected:YES animated:NO];
        
        [[ADLSingletonState sharedSingletonState] setDossierCourant:dossierRef];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDossierSelected object:dossierRef];
    }
    
    
}

-(void) cell:(RGFileCell *)cell didCheckAtIndexPath:(NSIndexPath *)indexPath
{
    [self.swipedCell hideMenuOptions];
    [cell.tableView deselectRowAtIndexPath:[cell.tableView indexPathForSelectedRow] animated:YES];
    NSString * dossierRef;
    if(cell.tableView == self.searchDisplayController.searchResultsTableView) {
        dossierRef = [[self.filteredDossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
    }
    else {
        dossierRef = [[self.dossiersArray objectAtIndex:indexPath.row] objectForKey:@"dossierRef"];
    }

    if ([self.selectedDossiersArray containsObject:dossierRef])
    {
        [self.selectedDossiersArray removeObject:dossierRef];
        if (self.selectedDossiersArray.count == 0) {
            [self setInBatchMode:NO];
        }
    }
    else
    {
        [self.selectedDossiersArray addObject:dossierRef];
        if (self.selectedDossiersArray.count == 1) {
            [self setInBatchMode:YES];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidBatchSelectionChange object:[self actionsForSelectedDossiers]];

}

/*- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}*/

#pragma mark - Wall delegate

-(void) didEndWithRequestAnswer:(NSDictionary *)answer {
    
    [self.refreshControl endRefreshing];
    if (_currentPage > 0) {
        [self.dossiersArray removeLastObject];
    }
    else {
        [self.dossiersArray removeAllObjects];
    }
    NSArray *dossiers = API_GETDOSSIERHEADERS_GET_DOSSIERS(answer);
    
    /* manualy filters the locked files out */
    if ([dossiers count] > 0) {
        NSMutableArray *lockedDossiers = [NSMutableArray arrayWithCapacity:[dossiers count]];
        for (NSDictionary *dossier in dossiers) {
            NSNumber *locked = [dossier objectForKey:@"locked"];
            if (locked && [locked isEqualToNumber:[NSNumber numberWithBool:YES]]) {
                [lockedDossiers addObject:dossier];
            }
        }
        if ([lockedDossiers count] > 0) {
            dossiers = [NSMutableArray arrayWithArray:dossiers];
            [(NSMutableArray*)dossiers removeObjectsInArray:lockedDossiers];
        }
    }
                 
    [self.dossiersArray addObjectsFromArray:dossiers];
    
    if ([dossiers count] > 15) {
        [[self loadMoreButton ] setHidden:NO];
    }
    else {
        [[self loadMoreButton ] setHidden:YES];
    }
    
    self.filteredDossiersArray = [NSMutableArray arrayWithCapacity:self.dossiersArray.count];
    
    self.selectedDossiersArray = [NSMutableArray arrayWithCapacity:self.dossiersArray.count];
    
    [((UITableView*)[self view]) reloadData];
    
    [[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
    
}

-(void) didEndWithUnAuthorizedAccess {
    
}

-(void) didEndWithUnReachableNetwork {
    
}

-(void) filterDossiersForSearchText:(NSString*) searchText {
    [self.filteredDossiersArray removeAllObjects];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K CONTAINS %@)", @"titre", searchText];
    [self.filteredDossiersArray addObjectsFromArray:[self.dossiersArray filteredArrayUsingPredicate:predicate]];
    
}


#pragma mark - UISearchDisplayDelegate protocol implementation

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterDossiersForSearchText:searchString];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

#pragma mark - FilterDelegate protocol implementation

- (void)shouldReload:(NSDictionary *)filter {
    [ADLSingletonState sharedSingletonState].currentFilter = [NSMutableDictionary dictionaryWithDictionary: filter];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    /*if (_filterModal != nil) {
        [_filterModal dismissViewControllerAnimated:NO completion:nil];
    }*/
    
    ((ADLFilterViewController *) segue.destinationViewController).delegate = self;
}

- (void)viewDidUnload {
    [self setLoadMoreButton:nil];
    [super viewDidUnload];
}

#pragma mark RGFileCellDataSource protocol implementation

-(BOOL) canSelectCell:(RGFileCell *)cell {
    return (!self.isInBatchMode);
}

-(BOOL) canSwipeCell:(RGFileCell *)cell {
    return (!self.isInBatchMode && (self.swipedCell == cell));
}

-(void) willSwipeCell:(RGFileCell *)cell {
    if (cell != self.swipedCell) {
        [self.swipedCell hideMenuOptions];
    }
    self.swipedCell = cell;
}

-(void) willSelectCell:(RGFileCell *)cell {
    if (self.swipedCell) {
        [self.swipedCell hideMenuOptions];
        self.swipedCell = nil;
    }
}

@end
