//
//  ADLActoinViewController.m
//  iParapheur
//
//  Created by Emmanuel Peralta on 13/10/12.
//
//

#import "ADLActionViewController.h"
#import "RGWorkflowDialogViewController.h"
#import "ADLSingletonState.h"
#import "ADLActionCell.h"
#import "ADLAPIHelper.h"

@interface ADLActionViewController ()

@end

@implementation ADLActionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated  {
    [super viewWillAppear:animated];
    if (_actions == nil) {
        _actions = [[NSMutableArray alloc] init];
    }
    /*else {
        [_actions removeAllObjects];
    }*/
    
    if (_labels == nil) {
        _labels = [[NSMutableArray alloc] init];
    }
    else {
        [_labels removeAllObjects];
    }
    
    if (!self.signatureEnabled) {
        [self.actions removeObject:@"SIGNER"];
    }
    for (NSString *action in self.actions) {
        [self.labels addObject:[ADLAPIHelper actionNameForAction:action]];
    }
    
    /*if (self.signatureEnabled) {
        [_actions addObject:@"SIGNER"];
        [_labels addObject:@"Signer"];
    }
    else if (self.visaEnabled) {
        [_actions addObject:@"VISER"];
        [_labels addObject:@"Viser"];
    }
    
    [_actions addObject:@"REJETER"];
    [_labels addObject:@"Rejeter"];*/
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *dossierRef = [[ADLSingletonState sharedSingletonState] dossierCourant];
    NSArray *dossiers = [NSArray arrayWithObject:dossierRef];
    [((RGWorkflowDialogViewController*) [segue destinationViewController]) setDossiersRef:dossiers];
    [((RGWorkflowDialogViewController*) [segue destinationViewController]) setAction:[segue identifier]];
}


#pragma mark - UITableView datasource
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_actions count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ADLActionCell* cell = (ADLActionCell*)[tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
    
    if (cell == nil) {
        cell = [[ADLActionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionCell"];
    }
    
    [[cell actionLabel] setText:[_labels objectAtIndex:[indexPath row]]];
    if ([[_actions objectAtIndex:[indexPath row]] isEqualToString:@"REJETER"]) {
        UIImage *rejectImg = [UIImage imageNamed:@"rejeter.png"];
        [[cell imageView] setImage:rejectImg];
    }
    else {
        [[cell imageView] setImage:[UIImage imageNamed:@"viser.png"]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    @try {
        [self performSegueWithIdentifier:[_actions objectAtIndex:[indexPath row]] sender:self];
    }
    @catch (NSException *exception) {
        [[[UIAlertView alloc] initWithTitle:@"Action impossible" message:@"Vous ne pouvez pas effectuer cette action sur tablette." delegate:nil cancelButtonTitle:@"Fermer" otherButtonTitles: nil] show];
    }
    @finally {}
}




- (void)viewDidUnload {
    [self setTableView:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
