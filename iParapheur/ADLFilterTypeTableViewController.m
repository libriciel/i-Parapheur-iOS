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
#import "ADLFilterTypeTableViewController.h"
#import "ADLAPIRequests.h"
#import "ADLSingletonState.h"
#import "ADLNotifications.h"
#import "ADLFilterSubTypeTableViewController.h"


@interface ADLFilterTypeTableViewController ()

@end


@implementation ADLFilterTypeTableViewController

- (id)initWithStyle:(UITableViewStyle)style {

	self = [super initWithStyle:style];
	if (self) {
		// Custom initialization
		_typology = [NSDictionary new];
	}
	return self;
}


- (void)viewDidLoad {

	[super viewDidLoad];

	// Uncomment the following line to preserve selection between presentations.
	// self.clearsSelectionOnViewWillAppear = NO;

	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
	NSString *bureauRef = [[ADLSingletonState sharedSingletonState] bureauCourant];

	NSDictionary *args = @{@"bureauRef" : bureauRef};

	API_REQUEST(@"getTypologie", args);
}


- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (IBAction)resetFilters:(id)sender {

	[[ADLSingletonState sharedSingletonState] setCurrentFilter:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kFilterChanged
	                                                    object:nil];
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	return _typology.allKeys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *CellIdentifier = @"TypeCell";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
	                                                             forIndexPath:indexPath];

	[cell.textLabel setText:_typology.allKeys[(NSUInteger) indexPath.row]];

	return cell;
}


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSDictionary *typologie = answer[@"data"][@"typology"];
	_typology = typologie;

	[((UITableView *) self.view) reloadData];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	NSString *selectedKey = _typology.allKeys[(NSUInteger) indexPath.row];
	NSArray *subTypes = _typology[selectedKey];

	((ADLFilterSubTypeTableViewController *) [segue destinationViewController]).subTypes = subTypes;
	[[ADLSingletonState sharedSingletonState] setCurrentFilter:[@{@"ph:typeMetier" : selectedKey} mutableCopy]];
	[[NSNotificationCenter defaultCenter] postNotificationName:kFilterChanged
	                                                    object:nil];

}


@end
