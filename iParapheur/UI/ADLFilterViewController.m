/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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


    NSDictionary *currentFilter = ADLSingletonState.sharedSingletonState.currentFilter;

    _titreTextField.text = currentFilter[@"titre"];
    NSString *selected = currentFilter[@"banette"];

    if (selected != nil)
        _selectedBanette = selected;
    else
        _selectedBanette = @"a-traiter";

    [_banetteButton setTitle:_banettesNames[_selectedBanette]
                    forState:UIControlStateNormal];

    _selectedTypes = [NSMutableArray arrayWithArray:currentFilter[@"types"]];
    _selectedSousTypes = [NSMutableArray arrayWithArray:currentFilter[@"sousTypes"]];

    _restClient = ADLRestClient.sharedManager;
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


- (void)reloadTypologyTable {

    for (NSString *selectedType in _selectedTypes) {

        int typeIndex = -1;
        for (int i = 0; i < _typologie.count; i++)
            if ([((ParapheurType *) _typologie[(NSUInteger) i]).name isEqualToString:selectedType])
                typeIndex = i;

        NSArray *sousTypes = ((ParapheurType *) _typologie[(NSUInteger) typeIndex]).subTypes;
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
    _banettePicker.backgroundColor = UIColor.clearColor;
    _banettePicker.showsSelectionIndicator = YES;
    _banettePicker.delegate = self;
    _banettePicker.dataSource = self;
    //_banettePicker.transform = CGAffineTransformMakeScale(-1, 1);
    // Adding it to a UIViewController
    UIViewController *pickerController = UIViewController.new;
    pickerController.preferredContentSize = CGSizeMake(320, 216);
    pickerController.view = _banettePicker;
    // Make it popover
    _pickerPopover = [UIPopoverController.alloc initWithContentViewController:pickerController];

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
