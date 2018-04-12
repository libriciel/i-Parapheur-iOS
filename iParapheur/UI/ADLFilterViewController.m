/*
 * Copyright 2012-2017, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
#import "ADLRestClient.h"


@interface ADLFilterViewController ()

@property(nonatomic, strong) NSArray *typologie;
@property(nonatomic, strong) NSMutableArray *selectedTypes;
@property(nonatomic, strong) NSMutableArray *selectedSousTypes;

@property(nonatomic, strong) NSDictionary *banettesNames;
@property(nonatomic, strong) NSArray *banettes;
@property(nonatomic, strong) NSString *selectedBanette;

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

	_banettesNames = @{
			@"en-preparation": @"À transmettre",
			@"a-traiter": @"À traiter",
			@"a-archiver": @"En fin de circuit",
			@"retournes": @"Retournés",
			@"en-cours": @"En cours",
			@"a-venir": @"À venir",
			@"recuperables": @"Récupérables",
			@"en-retard": @"En retard",
			@"traites": @"Traités",
			@"dossiers-delegues": @"Dossiers en délégation",
			@"no-corbeille": @"Toutes les banettes",
			@"no-bureau": @"Tout i-Parapheur"};
    
    _banettes = @[
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
		    @"no-bureau"];

    
    NSDictionary *currentFilter = [ADLSingletonState sharedSingletonState].currentFilter;
    
    _titreTextField.text = currentFilter[@"titre"];
    NSString * selected = currentFilter[@"banette"];
	
	if (selected != nil)
        _selectedBanette = selected;
    else
        _selectedBanette = @"a-traiter";

	[_banetteButton setTitle:_banettesNames[_selectedBanette]
	                forState:UIControlStateNormal];

	_selectedTypes = [NSMutableArray arrayWithArray:currentFilter[@"types"]];
	_selectedSousTypes = [NSMutableArray arrayWithArray:currentFilter[@"sousTypes"]];

	_restClient = [ADLRestClient sharedManager];
	[_restClient getTypology:nil
	                 success:^(NSArray *array) {
		                 _typologie = array;
		                 [_typesTableView reloadData];
		                 [self reloadTypologyTable];
	                 }
	                 failure:^(NSError *error) {
		                 // TODO : Error messages
	                 }];
}


- (void) reloadTypologyTable {

	for (NSString *selectedType in _selectedTypes) {
		
		int typeIndex = -1;
		for (int i=0; i<_typologie.count; i++)
			if ([((ParapheurType *)_typologie[(NSUInteger) i]).name isEqualToString:selectedType])
				typeIndex = i;

        NSArray *sousTypes = ((ParapheurType *)_typologie[(NSUInteger) typeIndex]).subTypes;
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
    NSDictionary *filter = @{
            @"titre": _titreTextField.text,
            @"banette": _selectedBanette,
            @"types": _selectedTypes,
            @"sousTypes": _selectedSousTypes};

    if ([_delegate respondsToSelector:@selector(shouldReload:)]) {
        [_delegate shouldReload:filter];
    }
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}


- (IBAction)handleClear:(id)sender {
    [_titreTextField setText:@""];
    _selectedBanette = @"a-traiter";
    [_banetteButton setTitle:_banettesNames[_selectedBanette]
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
    _banettePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
    _banettePicker.backgroundColor = [UIColor clearColor];
    _banettePicker.showsSelectionIndicator = YES;
    _banettePicker.delegate = self;
    _banettePicker.dataSource = self;
    //_banettePicker.transform = CGAffineTransformMakeScale(-1, 1);
    // Adding it to a UIViewController
    UIViewController *pickerController = [UIViewController new];
    [pickerController setPreferredContentSize:CGSizeMake(320, 216)];
    pickerController.view = _banettePicker;
    // Make it popover
    _pickerPopover = [[UIPopoverController alloc] initWithContentViewController:pickerController];

    // The anchor is on the banette button
    [_pickerPopover presentPopoverFromRect:((UIButton *) sender).frame
                                    inView:self.view
                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                  animated:YES];

    _pickerPopover.delegate = self;

    [_banettePicker selectRow:[_banettes indexOfObject:_selectedBanette]
                  inComponent:0
                     animated:NO];

}


#pragma mark - UITableViewDelegate protocol implementation


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    ParapheurType *type = _typologie[(NSUInteger) indexPath.section];
    NSString *sousType = type.subTypes[(NSUInteger) indexPath.row];

    [_selectedTypes addObject:type.name];
    [_selectedSousTypes addObject:sousType];
}


- (void)        tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    ParapheurType *type = _typologie[(NSUInteger) indexPath.section];
    NSString *sousType = type.subTypes[(NSUInteger) indexPath.row];

    [_selectedTypes removeObject:type.name];
    [_selectedSousTypes removeObject:sousType];

}


#pragma mark - UITableViewDataSource protocol implementation


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    ParapheurType *type = _typologie[(NSUInteger) section];
    return type.subTypes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"TypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    ParapheurType *type = _typologie[(NSUInteger) indexPath.section];
    NSString *sousType = type.subTypes[(NSUInteger) indexPath.row];
    cell.textLabel.text = sousType;
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _typologie.count;
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {

    return ((ParapheurType *) _typologie[(NSUInteger) section]).name;
}


#pragma mark - UIPickerViewDelegate protocol implementation


- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {

    _selectedBanette = _banettes[(NSUInteger) row];
    [_banetteButton setTitle:_banettesNames[_selectedBanette]
                    forState:UIControlStateNormal];
}


- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {

    return _banettesNames[_banettes[(NSUInteger) row]];
}


#pragma mark - UIPickerViewDataSource protocol implementation


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {

    return _banettes.count;
}


#pragma mark - UIPopoverControllerDelegate protocol implementation


@end
