//
//  ADLFilterTypeTableViewController.m
//  iParapheur
//
//  Created by Emmanuel Peralta on 21/02/13.
//
//

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
