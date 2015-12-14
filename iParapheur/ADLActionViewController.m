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


-(id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self) {
		// Custom initialization
	}
	return self;
}


-(void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"View Loaded : ActionViewController");
	
	// Uncomment the following line to preserve selection between presentations.
	// self.clearsSelectionOnViewWillAppear = NO;
 
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


-(void)viewWillAppear:(BOOL)animated {
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
	
	if (!_signatureEnabled) {
		[_actions removeObject:@"SIGNER"];
	}
	for (NSString *action in _actions) {
		[_labels addObject:[ADLAPIHelper actionNameForAction:action]];
	}
	
	if (_signatureEnabled && ![_actions containsObject:@"SIGNER"]) {
		[_actions addObject:@"SIGNER"];
		[_labels addObject:@"Signer"];
	}
	else if (_visaEnabled) {
	 [_actions addObject:@"VISER"];
	 [_labels addObject:@"Viser"];
	}
	
	[_actions addObject:@"REJETER"];
	[_labels addObject:@"Rejeter"];
	
	[[self tableView] reloadData];
}


-(void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	ADLResponseDossier *dossier = [ADLSingletonState sharedSingletonState].dossierCourantObject;
	NSArray *dossiers = @[dossier];
	((RGWorkflowDialogViewController*) segue.destinationViewController).dossiers = dossiers;
	((RGWorkflowDialogViewController*) segue.destinationViewController).action = segue.identifier;
}


#pragma mark - UITableView datasource


-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section {
	
	return _actions.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	ADLActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];

	if (cell == nil)
		cell = [[ADLActionCell alloc] initWithStyle:UITableViewCellStyleDefault
		                            reuseIdentifier:@"ActionCell"];

	cell.actionLabel.text = _labels[(NSUInteger) indexPath.row];

	if ([_actions[(NSUInteger) indexPath.row] isEqualToString:@"REJETER"])
		cell.imageView.image = [UIImage imageNamed:@"rejeter.png"];
	else
		[cell.imageView setImage:[UIImage imageNamed:@"viser.png"]];

	return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	@try {
		[self performSegueWithIdentifier:[_actions objectAtIndex:[indexPath row]] sender:self];
	}
	@catch (NSException *exception) {
		[[[UIAlertView alloc] initWithTitle:@"Action impossible"
									message:@"Vous ne pouvez pas effectuer cette action sur tablette."
								   delegate:nil
						  cancelButtonTitle:@"Fermer"
						  otherButtonTitles: nil] show];
	}
	@finally {}
}


-(void)viewDidUnload {
	[self setTableView:nil];
	[self setTableView:nil];
	[super viewDidUnload];
}


@end
