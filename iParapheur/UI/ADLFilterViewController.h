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

#import <UIKit/UIKit.h>
#import "ADLSingletonState.h"


@protocol FilterDelegate;
@class ADLRestClient;
//@protocol FilterDataSource;

@interface ADLFilterViewController : UIViewController
		<UITableViewDataSource,
		UITableViewDelegate,
		UIPickerViewDataSource,
		UIPickerViewDelegate,
		UIPopoverControllerDelegate>

@property(weak) id <FilterDelegate> delegate;

@property(strong, nonatomic) IBOutlet UITextField *titreTextField;
@property(strong, nonatomic) IBOutlet UITableView *typesTableView;
@property(strong, nonatomic) IBOutlet UIButton *banetteButton;
@property(strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property(nonatomic, strong) ADLRestClient *restClient;

// Picker pour le choix des banettes, présent dans le popover en dessous.
@property(strong, nonatomic) UIPickerView *banettePicker;
@property(strong, nonatomic) UIPopoverController *pickerPopover;

@end


// Protocol permettant le traitement de l'application du filtre
@protocol FilterDelegate <NSObject>

@required
- (void)shouldReload:(NSDictionary *)filter;

@end


// Protocol permettant de récupérer les infos du dossier à afficher
/*@protocol FilterDataSource <NSObject>

@required
- (NSInteger *)numberOfTypeForDossier:(NSString *) dossier;
- (NSInteger *)numberOfsousTypesForDossier:(NSString *)dossier andType:(NSString *)type;
- (BOOL) isAvenirEnableForDossier:(NSString *)dossier;


@end*/

