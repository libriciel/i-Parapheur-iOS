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
    _possibleMainActions = [NSArray arrayWithObjects:@"VISER", @"SIGNER", @"TDT", @"MAILSEC", @"ARCHIVER", nil];
    _actionsWithoutAnnotation = [NSArray arrayWithObjects:@"RECUPERER", @"SUPPRIMER", @"SECRETARIAT", nil];
    [self loadDossiersWithPage:_currentPage];
}


-(void) setInBatchMode:(BOOL) value {
    _inBatchMode = value;
    
}

-(void)loadDossiersWithPage:(int)page
{
    NSDictionary *currentFilter = [[ADLSingletonState sharedSingletonState] currentFilter];
    if (currentFilter != nil) {
        //API_GETDOSSIERHEADERS_FILTERED(self.deskRef, [NSNumber numberWithInteger:page], @"15", currentFilter);
        
        // TYPES
        NSMutableArray *types = [NSMutableArray new];
        for (NSString *type in [currentFilter objectForKey:@"types"]) {
            [types addObject:[NSDictionary dictionaryWithObject:type forKey:@"ph:typeMetier"]];
        }
        // SOUS TYPES
        NSMutableArray *sousTypes = [NSMutableArray new];
        for (NSString *sousType in [currentFilter objectForKey:@"sousTypes"]) {
            [sousTypes addObject:[NSDictionary dictionaryWithObject:sousType forKey:@"ph:soustypeMetier"]];
        }
        
        // TITRE
        NSDictionary *titre = [NSDictionary dictionaryWithObject:
                               [NSArray arrayWithObject:
                                [NSDictionary dictionaryWithObject:
                                 [NSString stringWithFormat:@"*%@*", [currentFilter objectForKey:@"titre"]]
                                                            forKey:@"cm:title"]]
                                                          forKey:@"or"];
        
        NSDictionary *filtersDictionnary = [NSDictionary dictionaryWithObject:
                                  [NSArray arrayWithObjects:
                                   [NSDictionary dictionaryWithObject:types forKey:@"or"],
                                   [NSDictionary dictionaryWithObject:sousTypes forKey:@"or"],
                                    titre,
                                    nil] forKey:@"and"];

        API_GETDOSSIERHEADERS_FILTERED(self.deskRef, [NSNumber numberWithInteger:page], @"15", [currentFilter objectForKey:@"banette"], filtersDictionnary);
    }
    else {
        API_GETDOSSIERHEADERS(self.deskRef, [NSNumber numberWithInteger:page], @"15");
    }
}

#pragma mark Actions

-(void) updateToolBar
{
    if (self.isInBatchMode) {
        if (self.navigationController.toolbarHidden) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
        NSArray *actions = [self actionsForSelectedDossiers];
        // Normalement il n'y a toujours qu'une seule action principale.
        NSArray *mainActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.possibleMainActions]];
        self.secondaryActions = [actions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.possibleMainActions]];
        
        NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithCapacity:3];
        
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil]];
        
        if (self.secondaryActions.count > 0) {
            UIButton *moreActions = [UIButton buttonWithType:UIButtonTypeCustom];
            moreActions.backgroundColor = [UIColor darkGrayColor];
            moreActions.frame = CGRectMake(0.0f, 0.0f, 90.0f, CGRectGetHeight(self.navigationController.toolbar.bounds));
            [moreActions setTitle:@"Plus" forState:UIControlStateNormal];
            [moreActions setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [moreActions addTarget:self action:@selector(showMoreActions:) forControlEvents:UIControlEventTouchUpInside];
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

-(void) mainActionPressed {
    if (self.mainAction) {
        @try {
            [self performSegueWithIdentifier:self.mainAction sender:self];
        }
        @catch (NSException *exception) {
            [[[UIAlertView alloc] initWithTitle:@"Action impossible" message:@"Vous ne pouvez pas effectuer cette action sur tablette." delegate:nil cancelButtonTitle:@"Fermer" otherButtonTitles: nil] show];
        }
        @finally {}
    }
}

-(void) showMoreActions:(id) sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Traitement par lot"
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
        [actionSheet showFromBarButtonItem:moreItem animated:YES];
    }
    //[(UIView*) sender convertRect:((UIView*)sender).frame toView:self.view];
    else {
        [actionSheet showFromRect:((UIView*)sender).frame inView:self.view animated:YES];
    }
}

- (IBAction)loadNextResultsPage:(id)sender {
    [self loadDossiersWithPage:++_currentPage]; 
}

-(NSArray*) actionsForSelectedDossiers {
    NSMutableArray* actions;
    for (NSDictionary* dossier in self.selectedDossiersArray) {
        NSArray* dossierActions = [ADLAPIHelper actionsForDossier:dossier];
        if (!actions) { // the first dossier only
            actions = [NSMutableArray arrayWithArray:dossierActions];
        }
        else {
            [actions filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", dossierActions]];
        }
    }
    return actions;
}


#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredDossiersArray count];
    //} else {
    //    return [self.dossiersArray count];
    //}
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"dossierCell";
    
    RGFileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.delegate = self;
    
    NSDictionary *dossier;
    //if (tableView == self.searchDisplayController.searchResultsTableView) {
        dossier = [self.filteredDossiersArray objectAtIndex:[indexPath row]];
    //} else {
    //    dossier = [self.dossiersArray objectAtIndex:[indexPath row]];
    //}
    
    // NSLog(@"%@", [dossier objectForKey:@"titre"]);
    
    cell.dossierTitleLabel.text = [dossier objectForKey:@"titre"];
    cell.typologyLabel.text = [NSString stringWithFormat:@"%@ / %@", [dossier objectForKey:@"type"], [dossier objectForKey:@"sousType"]];
    
    if ([[[dossier objectForKey:@"actions"] objectForKey:@"sign"] boolValue] || [[[dossier objectForKey:@"actions"] objectForKey:@"archive"] boolValue]) {
        //actionName = API_ACTION_NAME_FOR_ACTION([dossier objectForKey:@"actionDemandee"]);

        NSString *actionName = [ADLAPIHelper actionNameForAction:[dossier objectForKey:@"actionDemandee"]];
        
        [cell.validateButton setTitle:actionName forState:UIControlStateNormal];
    }
    else {
        cell.validateButton.hidden = YES;
    }
    
    
    NSString *dateLimite = [dossier objectForKey:@"dateLimite"];
    if (dateLimite != nil) {
        ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
        //[formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH:mm:ss'Z'"];
        NSDate *dueDate = [formatter dateFromString:dateLimite];
        
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateStyle:NSDateFormatterShortStyle];
        [outputFormatter setTimeStyle:NSDateFormatterNoStyle];
        //[outputFormatter setDateFormat:@"dd MMM"];
        
        NSString *fdate = [outputFormatter stringFromDate:dueDate];
        cell.retardBadge.badgeText = fdate;
        [cell.retardBadge autoBadgeSizeWithString: fdate];
        [cell.retardBadge setHidden:NO];

    }
    else {
        [cell.retardBadge setHidden:YES];
    }
    cell.switchButton.on = [self.selectedDossiersArray containsObject:dossier];
    
    return cell;
}


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
    
    self.filteredDossiersArray = [NSArray arrayWithArray:self.dossiersArray];
    
    self.selectedDossiersArray = [NSMutableArray arrayWithCapacity:self.dossiersArray.count];
    
    [((UITableView*)[self view]) reloadData];
    
    [[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationNone];
    
}

-(void) didEndWithUnAuthorizedAccess {
    
}

-(void) didEndWithUnReachableNetwork {
    
}

-(void) filterDossiersForSearchText:(NSString*) searchText {
    
    if (searchText && (searchText.length > 0)) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K CONTAINS[cd] %@)", @"titre", searchText];
        self.filteredDossiersArray = [self.dossiersArray filteredArrayUsingPredicate:predicate];
    }
    else {
        self.filteredDossiersArray = [NSArray arrayWithArray:self.dossiersArray];
    }
    
}


#pragma mark - UISearchBarDelegate protocol implementation

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterDossiersForSearchText:searchText];
    [self.tableView reloadData];
}

#pragma mark - FilterDelegate protocol implementation

- (void)shouldReload:(NSDictionary *)filter {
    [ADLSingletonState sharedSingletonState].currentFilter = [NSMutableDictionary dictionaryWithDictionary: filter];
    [[NSNotificationCenter defaultCenter] postNotificationName:kFilterChanged object:nil];
    [self refresh];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"filterSegue"]) {
        ((ADLFilterViewController *) segue.destinationViewController).delegate = self;
    }
    else {
        ((RGWorkflowDialogViewController*) segue.destinationViewController).dossiersRef = [self.selectedDossiersArray valueForKey:@"dossierRef"];
        ((RGWorkflowDialogViewController*) segue.destinationViewController).action = segue.identifier;
    }
}

- (void)viewDidUnload {
    [self setLoadMoreButton:nil];
    [super viewDidUnload];
}

#pragma mark UIActionSheetDelegate protocol implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex < self.secondaryActions.count) {
        NSString *action = [self.secondaryActions objectAtIndex:buttonIndex];
        @try {
            [self performSegueWithIdentifier:action sender:self];
        }
        @catch (NSException *exception) {
            [[[UIAlertView alloc] initWithTitle:@"Action impossible" message:@"Vous ne pouvez pas effectuer cette action sur tablette." delegate:nil cancelButtonTitle:@"Fermer" otherButtonTitles: nil] show];
        }
        @finally {}
    }
}

#pragma mark RGFileCellDelegate protocol implementation

-(void) cell:(RGFileCell *)cell didSelectAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.tableView deselectRowAtIndexPath:[cell.tableView indexPathForSelectedRow] animated:NO];
    
    [cell.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    //if (!self.isInBatchMode) {
        
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
    //}
    
    
}

-(void) cell:(RGFileCell *)cell didCheckAtIndexPath:(NSIndexPath *)indexPath
{
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

-(void) cell:(RGFileCell*)cell didTouchSecondaryButtonAtIndexPath:(NSIndexPath*) indexPath {
    NSDictionary *dossier = [self.dossiersArray objectAtIndex:indexPath.row];
    self.secondaryActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", self.possibleMainActions]];
    self.selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
    [self showMoreActions:cell];
}

-(void) cell:(RGFileCell*)cell didTouchMainButtonAtIndexPath:(NSIndexPath*) indexPath {
    NSDictionary *dossier = [self.dossiersArray objectAtIndex:indexPath.row];
    NSArray *mainActions = [[ADLAPIHelper actionsForDossier:dossier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF IN %@", self.possibleMainActions]];
    if (mainActions.count > 0) {
        self.mainAction = [mainActions objectAtIndex:0];
        self.selectedDossiersArray = [NSMutableArray arrayWithObject:dossier];
        [self mainActionPressed];
        
    }
}


-(BOOL) canSelectCell:(RGFileCell *)cell {
    return YES;
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
