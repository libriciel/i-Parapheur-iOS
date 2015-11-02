
#import "SettingsTableViewController.h"


@implementation SettingsTableViewController {
	IBOutlet UIBarButtonItem *backButton;
	NSDictionary *rowsDictionary;
}

- (void)viewDidLoad {
	NSLog(@"View Loaded : SettingsTableViewController");

	backButton.target = self;
	backButton.action = @selector(onBackButtonClicked);

	rowsDictionary = @{
			@"Général" : @[@"Comptes", @"Certificats"],
			@"À propos" : @[@"Informations légales", @"Licences tierces"]
	};
}


#pragma mark - UITableViewDatasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return rowsDictionary.count;
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {

	return rowsDictionary.allKeys[(NSUInteger) section];
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	NSArray *sectionArray = rowsDictionary[rowsDictionary.allKeys[(NSUInteger) section]];
	return sectionArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{

	static NSString *MyIdentifier = @"SettingCell";
	UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:MyIdentifier];

	if (cell == nil)
		cell = [[UITableViewCell new] initWithStyle:UITableViewCellStyleDefault
		                            reuseIdentifier:MyIdentifier];

	NSArray *sectionArray = rowsDictionary[rowsDictionary.allKeys[(NSUInteger) indexPath.section]];
	cell.textLabel.text = sectionArray[(NSUInteger) indexPath.row];

	return cell;
}


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSArray *sectionArray = rowsDictionary[rowsDictionary.allKeys[(NSUInteger) indexPath.section]];
	NSLog(@"Adrien - selected : %@", sectionArray[(NSUInteger) indexPath.row]);
}


#pragma mark - Buttons callbacks

- (void)onBackButtonClicked {

	[self.presentingViewController dismissViewControllerAnimated:YES
	                                                  completion:nil];
}


@end