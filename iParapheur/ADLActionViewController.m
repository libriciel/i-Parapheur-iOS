/*
 * Copyright 2012-2016, Adullact-Projet.
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
#import "ADLActionViewController.h"
#import "RGWorkflowDialogViewController.h"
#import "ADLActionCell.h"
#import "ADLAPIHelper.h"


@interface ADLActionViewController ()

@end


@implementation ADLActionViewController


- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	return self;
}


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : ActionViewController");

	// Uncomment the following line to preserve selection between presentations.
	// self.clearsSelectionOnViewWillAppear = NO;

	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];

	_actions = [Dossier filterActions:@[_currentDossier]];
	_labels = [NSMutableArray new];

	for (NSString *action in _actions)
		[_labels addObject:[ADLAPIHelper actionNameForAction:action
		                                       withPaperSign:_currentDossier.unwrappedIsSignPapier]];

	// 66 pixels, times the number of rows.
	// Row size is hardcoded in the Storyboard
	self.preferredContentSize = CGSizeMake(300, 66 * _actions.count);

	[self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {

	[self setTableView:nil];
	[self setTableView:nil];

	[super didReceiveMemoryWarning];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	NSArray *dossiers = @[_currentDossier];
	((RGWorkflowDialogViewController *) segue.destinationViewController).dossiers = dossiers;
	((RGWorkflowDialogViewController *) segue.destinationViewController).action = segue.identifier;
}


#pragma mark - UITableView datasource


- (NSInteger)tableView:(UITableView *)tableView
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

	if ([_actions[(NSUInteger) indexPath.row] isEqualToString:@"REJET"])
		cell.imageView.image = [UIImage imageNamed:@"rejeter.png"];
	else
		[cell.imageView setImage:[UIImage imageNamed:@"viser.png"]];

	return cell;
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	@try {
		[self performSegueWithIdentifier:_actions[(NSUInteger) indexPath.row]
		                          sender:self];
	}
	@catch (NSException *exception) {
		[[[UIAlertView alloc] initWithTitle:@"Action impossible"
		                            message:@"Vous ne pouvez pas effectuer cette action sur tablette."
		                           delegate:nil
		                  cancelButtonTitle:@"Fermer"
		                  otherButtonTitles:nil] show];
	}
	@finally {}
}


@end
