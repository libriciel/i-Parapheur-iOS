/*
 * Contributors : SKROBS (2012)
 * Copyright 2012-2019, Libriciel SCOP.
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
#import "RGWorkflowDialogViewController.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "iParapheur-Swift.h"


#define RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PAPER_SIGNATURE 1
#define RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PASSWORD_SIGNATURE 2


@interface RGWorkflowDialogViewController () {
    NSMutableDictionary *circuits;
}


@end


@implementation RGWorkflowDialogViewController


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];

    if (self) {
        // Custom initialization
    }

    return self;
}


#pragma mark - LifeCycle


- (void)viewDidLoad {

    [super viewDidLoad];
    NSLog(@"View Loaded : RGWorkflowDialogViewController");

    _restClient = ADLRestClient.sharedManager;
    circuits = NSMutableDictionary.new;
    _bureauCourant = ADLSingletonState.sharedSingletonState.bureauCourant;
}


- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    _navigationBar.topItem.title = NSLocalizedString(_action, @"");

    if ([_action isEqualToString:@"SIGNATURE"] && !_isPaperSign) {
        _navigationBar.topItem.rightBarButtonItem.enabled = NO;
    } else {
        _certificateLabel.hidden = YES;
        _certificatesTableView.hidden = YES;

        if ([_action isEqualToString:@"REJET"])
            _annotationPubliqueLabel.text = @"Motif de rejet (obligatoire)";
    }

    // Paper Signature

    BOOL isSignPapier = true;
    for (Dossier *dossier in _dossiers)
        isSignPapier = isSignPapier && dossier.isSignPapier;

    [_paperSignatureButton addTarget:self
                              action:@selector(onPaperSignatureButtonClicked:)
                    forControlEvents:UIControlEventTouchUpInside];

    _pkeys = [ModelsDataController fetchCertificates];
}


- (void)viewDidAppear:(BOOL)animated {

    [self retrieveCircuitsForDossierAtIndex:0];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return YES;
}


#pragma mark - Private methods


- (IBAction)finish:(id)sender {

}


- (IBAction)cancel:(id)sender {

    [self dismissViewControllerAnimated:YES
                             completion:nil];
}


- (void)dismissDialogView {

    [self dismissViewControllerAnimated:YES
                             completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DossierActionComplete"
                                                        object:nil];
}

/**
 * Retrieve every circuit, to fetch isDigitalSignatureMandatory value.
 * We can't launch every request at the same time, a new one will cancel the previous.
 * That's why we have to reccursively call this method, with incremented index, to fetch every circuit.
 */
- (void)retrieveCircuitsForDossierAtIndex:(NSUInteger)index {

    if (index >= _dossiers.count)
        return;

    __weak typeof(self) weakSelf = self;
    if ([_dossiers[index] isDelegue] == false) {
        [_restClient getCircuit:((Dossier *) _dossiers[index]).identifier
                        success:^(Circuit *circuit) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            if (strongSelf) {
                                circuits[((Dossier *) _dossiers[index]).identifier] = circuit;
                                [strongSelf checkSignPapierButtonVisibility];
                                [strongSelf retrieveCircuitsForDossierAtIndex:(index + 1)];
                            }
                        }
                        failure:^(NSError *error) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            if (strongSelf) {
                                circuits[((Dossier *) _dossiers[index]).identifier] = nil;
                                [strongSelf checkSignPapierButtonVisibility];
                                [strongSelf retrieveCircuitsForDossierAtIndex:(index + 1)];
                            }
                        }];
    }
}

/**
 * Switch every Dossier to paper signature.
 * We can't launch every request at the same time, a new one will cancel the previous.
 * That's why we have to reccursively call this method, with incremented index, to fetch every circuit.
 */
- (void)switchToPaperSigntureForDocumentAtIndex:(NSUInteger)index {

    if (index >= _dossiers.count) {
        [self dismissDialogView];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [_restClient actionSwitchToPaperSignatureForDossier:((Dossier *) _dossiers[index]).identifier
                                              forBureau:_bureauCourant
                                                success:^(NSArray *success) {
                                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                                    if (strongSelf)
                                                        [strongSelf switchToPaperSigntureForDocumentAtIndex:(index + 1)];
                                                }
                                                failure:^(NSError *error) {
                                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                                    if (strongSelf)
                                                        [strongSelf switchToPaperSigntureForDocumentAtIndex:(index + 1)];
                                                }];
}


- (void)checkSignPapierButtonVisibility {

//	BOOL isSignMandatory = false;
//
//	for (Dossier *dossier in _dossiers)
//		if (dossier.isDelegue == false) // TODO Adrien : Fix this
//			if ((circuits[dossier.unwrappedId] == nil) || (((ADLResponseCircuit *) circuits[dossier.unwrappedId]).isDigitalSignatureMandatory))
//				isSignMandatory = true;
//
//	if ([_action isEqualToString:@"SIGNATURE"] && (!_isPaperSign))
//		_paperSignatureButton.hidden = isSignMandatory;
    _paperSignatureButton.hidden = true; // TODO Adrien : Fix this
}


#pragma mark - UIButton delegate


- (void)onPaperSignatureButtonClicked:(id)sender {

    UIAlertView *signPapierConfirm =
            [[UIAlertView alloc] initWithTitle:@"Voulez vous réellement changer le mode de signature de ce dossier vers le mode signature papier ?"
                                       message:@"Vous devrez imprimer et signer le document manuellement."
                                      delegate:self
                             cancelButtonTitle:@"Annuler"
                             otherButtonTitles:@"Confirmer", nil];

    signPapierConfirm.tag = RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PAPER_SIGNATURE;
    [signPapierConfirm show];
}


#pragma mark - UITableView Datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    return _pkeys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PKeyCell"];

    if (cell == nil)
        cell = UITableViewCell.new;

    Certificate *pkey = _pkeys[(NSUInteger) indexPath.row];
    cell.textLabel.text = pkey.commonName;

    return cell;
}


#pragma mark - UITableView delegate


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // we selected a private key now fetching it

    _currentPKey = _pkeys[(NSUInteger) indexPath.row];

    // now we have a pkey we can activate Sign Button
    _navigationBar.topItem.rightBarButtonItem.enabled = YES;
}


#pragma mark - UIAlertView delegate


- (void)   alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {

}


@end
