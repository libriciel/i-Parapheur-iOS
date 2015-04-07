//
//  RGFilterViewController.m
//  iParapheur
//
//  Created by Jason MAIRE on 16/01/2014.
//
//

#import "ADLFilterViewController.h"
#import "ADLAPIRequests.h"
#import "UIColor+CustomColors.h"

@interface ADLFilterViewController ()

@property (nonatomic, strong) NSDictionary* typologie;
@property (nonatomic, strong) NSMutableArray* selectedTypes;
@property (nonatomic, strong) NSMutableArray* selectedSousTypes;

@property (nonatomic, strong) NSDictionary* banettesNames;
@property (nonatomic, strong) NSArray* banettes;
@property (nonatomic, strong) NSString* selectedBanette;

@end

@implementation ADLFilterViewController


- (void)viewDidLoad {
	[super viewDidLoad];

	// TODO : Fix requests, and reset bannettePicker visible

    _navigationBar.topItem.title = @"Filtrer";
    _typesTableView.dataSource = self;
    _typesTableView.delegate = self;
    _banettePicker.delegate = self;
    _banettePicker.dataSource = self;
	
    _banettesNames = [NSDictionary dictionaryWithObjectsAndKeys:
                     @"À transmettre", @"en-preparation",
                     @"À traiter", @"a-traiter",
                     @"En fin de circuit", @"a-archiver",
                     @"Retournés", @"retournes",
                     @"En cours", @"en-cours",
                     @"À venir", @"a-venir",
                     @"Récupérables", @"recuperables",
                     @"En retard", @"en-retard",
                     @"Traités", @"traites",
                     @"Dossiers en délégation", @"dossiers-delegues",
                     @"Toutes les banettes", @"no-corbeille",
                     @"Tout i-Parapheur", @"no-bureau",
                     nil];
    
    _banettes = [NSArray arrayWithObjects:
                     @"en-preparation",
                     @"a-traiter",
                     @"a-archiver",
                     @"retournes",
                     @"en-cours",
                     @"a-venir",
                     @"recuperables",
                     @"en-retard",
                     @"traites",
                     @"dossiers-delegues",
                     @"no-corbeille",
                     @"no-bureau",
                     nil];

    
    NSDictionary *currentFilter = [[ADLSingletonState sharedSingletonState] currentFilter];
    
    _titreTextField.text = [currentFilter objectForKey:@"titre"];
    NSString * selected = [currentFilter objectForKey:@"banette"];
	
	if (selected != nil)
        _selectedBanette = selected;
    else
        _selectedBanette = @"a-traiter";

	[_banetteButton setTitle:[_banettesNames objectForKey:_selectedBanette]
						forState:UIControlStateNormal];
    
    _selectedTypes = [NSMutableArray arrayWithArray:[currentFilter objectForKey:@"types"]];
    _selectedSousTypes = [NSMutableArray arrayWithArray:[currentFilter objectForKey:@"sousTypes"]];

    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:@"true", @"getAll", nil];

    API_REQUEST(@"getTypologie", args);
}


- (void) reloadTypologyTable {
    for (NSString *selectedType in _selectedTypes) {
        int typeIndex = (int)[[_typologie allKeys] indexOfObject:selectedType];
        NSArray *sousTypes = [_typologie objectForKey:selectedType];
        for (NSString *selectedSousType in _selectedSousTypes) {
            NSUInteger sousTypeIndex = [sousTypes indexOfObject:selectedSousType];
            if (sousTypeIndex != NSNotFound) {
                [_typesTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:sousTypeIndex
																		 inSection:typeIndex]
											 animated:YES
									   scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
}


- (IBAction)handleSave:(id)sender {
    NSDictionary * filter = [NSDictionary dictionaryWithObjectsAndKeys:
                             _titreTextField.text, @"titre",
                             _selectedBanette, @"banette",
                             _selectedTypes, @"types",
                             _selectedSousTypes, @"sousTypes",
                             nil];
    
    if ([_delegate respondsToSelector:@selector(shouldReload:)]) {
        [_delegate shouldReload:filter];
    }
    [self dismissViewControllerAnimated:YES
							 completion:nil];
}


- (IBAction)handleClear:(id)sender {
    [_titreTextField setText:@""];
    _selectedBanette = @"a-traiter";
    [_banetteButton setTitle:[_banettesNames objectForKey:_selectedBanette]
					forState:UIControlStateNormal];
    [_selectedSousTypes removeAllObjects];
    [_selectedTypes removeAllObjects];
    [_typesTableView reloadData];
}


- (IBAction)handleCancel:(id)sender {
    [self dismissViewControllerAnimated:YES
							 completion:nil];
}


- (IBAction)displayBanettePicker:(id)sender {
    
    // Setting banette UIPickerView
    self.banettePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
    self.banettePicker.backgroundColor = [UIColor clearColor];
    self.banettePicker.showsSelectionIndicator = YES;
    self.banettePicker.delegate = self;
    self.banettePicker.dataSource = self;
    //self.banettePicker.transform = CGAffineTransformMakeScale(-1, 1);
    // Adding it to a UIViewController
    UIViewController *pickerController = [UIViewController new];
    [pickerController setPreferredContentSize:CGSizeMake(320, 216)];
    pickerController.view = self.banettePicker;
    // Make it popover
    self.pickerPopover = [[UIPopoverController alloc] initWithContentViewController:pickerController];
    
    // The anchor is on the banette button
    [self.pickerPopover presentPopoverFromRect:((UIButton *)sender).frame
										inView:self.view
					  permittedArrowDirections:UIPopoverArrowDirectionAny
									  animated:YES];
    
    self.pickerPopover.delegate = self;
	
    [self.banettePicker selectRow:[self.banettes indexOfObject:self.selectedBanette]
					  inComponent:0
						 animated:NO];

}


#pragma mark - ADLParapheurWallDelegate protocol implementation


- (void)didEndWithRequestAnswer:(NSDictionary*)answer {
    self.typologie = [[answer objectForKey:@"data"] objectForKey:@"typology"];
    [self.typesTableView reloadData];
    [self reloadTypologyTable];
}


#pragma mark - UITableViewDelegate protocol implementation


- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSString* type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    NSString* sousType = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    
    [self.selectedTypes addObject:type];
    [self.selectedSousTypes addObject:sousType];
}


- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSString* type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    NSString* sousType = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    
    [self.selectedTypes removeObject:type];
    [self.selectedSousTypes removeObject:sousType];

}


#pragma mark - UITableViewDataSource protocol implementation


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	
    NSString * type = [[self.typologie allKeys] objectAtIndex:section];
    return [[self.typologie objectForKey:type] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *CellIdentifier = @"TypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString * type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    NSString * sousType = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    cell.textLabel.text = sousType;
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.typologie count];
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
	
    return [[self.typologie allKeys] objectAtIndex:section];
}


#pragma mark - UIPickerViewDelegate protocol implementation


- (void)pickerView:(UIPickerView *)pickerView
	  didSelectRow:(NSInteger)row
	   inComponent:(NSInteger)component {
	
    self.selectedBanette = [self.banettes objectAtIndex:row];
    [self.banetteButton setTitle:[self.banettesNames objectForKey:self.selectedBanette]
						forState:UIControlStateNormal];
}


- (NSString *)pickerView:(UIPickerView *)pickerView
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component {
	
    return [self.banettesNames objectForKey:[self.banettes objectAtIndex:row]];
}


#pragma mark - UIPickerViewDataSource protocol implementation


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
	
    return self.banettes.count;
}


#pragma mark - UIPopoverControllerDelegate protocol implementation


@end
