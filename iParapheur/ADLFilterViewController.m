//
//  RGFilterViewController.m
//  iParapheur
//
//  Created by Jason MAIRE on 16/01/2014.
//
//

#import "ADLFilterViewController.h"
#import "ADLAPIRequests.h"

@interface ADLFilterViewController ()

@property (nonatomic, strong) NSDictionary* typologie;
@property (nonatomic, strong) NSMutableSet* selectedTypes;
@property (nonatomic, strong) NSMutableSet* selectedSousTypes;

@property (nonatomic, strong) NSArray* banettes;
@property (nonatomic, strong) NSString* selectedBanette;

@end

@implementation ADLFilterViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationBar.topItem.title = @"Filtrer";
    self.selectedTypes = [NSMutableSet new];
    self.selectedSousTypes = [NSMutableSet new];
    self.typesTableView.dataSource = self;
    self.typesTableView.delegate = self;
    self.banettePicker.delegate = self;
    self.banettePicker.dataSource = self;
    
    /*self.banettes = [NSDictionary dictionaryWithObjectsAndKeys:
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
                     nil];*/
    self.banettes = [NSArray arrayWithObjects:@"À transmettre",
                     @"À traiter",
                     @"En fin de circuit",
                     @"Retournés",
                     @"En cours",
                     @"À venir",
                     @"Récupérables",
                     @"En retard",
                     @"Traités",
                     @"Dossiers en délégation",
                     @"Toutes les banettes",
                     @"Tout i-Parapheur",
                     nil];
    
    NSString * selected = [[[ADLSingletonState sharedSingletonState] currentFilter] objectForKey:@"banette"];
    if (selected != nil) {
        self.selectedBanette = selected;
    }
    else {
        self.selectedBanette = [self.banettes objectAtIndex:1];
    }
    [self.banetteButton setTitle:self.selectedBanette forState:UIControlStateNormal];
    NSString *bureauRef = [[ADLSingletonState sharedSingletonState] bureauCourant];
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:bureauRef, @"bureauRef", nil];


    API_REQUEST(@"getTypologie", args);
}

- (IBAction)handleSave:(id)sender {
    NSDictionary * filter = [NSDictionary dictionaryWithObjectsAndKeys:
                             self.titreTextField.text, @"title",
                             self.selectedBanette, @"banette",
                             self.selectedTypes, @"types",
                             self.selectedSousTypes, @"sousTypes",
                             nil];
    
    if ([self.delegate respondsToSelector:@selector(shouldReload:)]) {
        [self.delegate shouldReload:filter];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)handleCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)displayBanettePicker:(id)sender {
    
    // Setting banette UIPickerView
    self.banettePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 216, 150)];
    self.banettePicker.backgroundColor = [UIColor clearColor];
    self.banettePicker.showsSelectionIndicator = YES;
    self.banettePicker.delegate = self;
    self.banettePicker.dataSource = self;
    //self.banettePicker.transform = CGAffineTransformMakeScale(-1, 1);
    // Adding it to a UIViewController
    UIViewController *pickerController = [UIViewController new];
    pickerController.view = self.banettePicker;
    // Make it popover
    self.pickerPopover = [[UIPopoverController alloc] initWithContentViewController:pickerController];
    // The anchor is on the banette button
    [self.pickerPopover presentPopoverFromRect:((UIButton *)sender).frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    self.pickerPopover.delegate = self;
    [self.banettePicker selectRow:[self.banettes indexOfObject:self.selectedBanette] inComponent:0 animated:NO];

}


#pragma mark - ADLParapheurWallDelegate protocol implementation

- (void)didEndWithRequestAnswer:(NSDictionary*)answer {
    self.typologie = [[answer objectForKey:@"data"] objectForKey:@"typology"];
    
    [self.typesTableView reloadData];
}

#pragma mark - UITableViewDelegate protocol implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    NSString* sousType = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    
    [self.selectedTypes addObject:type];
    [self.selectedSousTypes addObject:sousType];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    NSString* sousType = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    
    [self.selectedTypes removeObject:type];
    [self.selectedSousTypes removeObject:sousType];

}


#pragma mark - UITableViewDataSource protocol implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString * type = [[self.typologie allKeys] objectAtIndex:section];
    return [[self.typologie objectForKey:type] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString * type = [[self.typologie allKeys] objectAtIndex:indexPath.section];
    cell.textLabel.text = [[self.typologie objectForKey:type] objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.typologie count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.typologie allKeys] objectAtIndex:section];
}

#pragma mark - UIPickerViewDelegate protocol implementation

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedBanette = [self.banettes objectAtIndex:row];
    [self.banetteButton setTitle:self.selectedBanette forState:UIControlStateNormal];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.banettes objectAtIndex:row];
}



#pragma mark - UIPickerViewDataSource protocol implementation

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.banettes.count;
}

#pragma mark - UIPopoverControllerDelegate protocol implementation





@end
