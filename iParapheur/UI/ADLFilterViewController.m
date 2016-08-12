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
#import "ADLFilterViewController.h"
#import "ADLAPIRequests.h"

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
