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

#import <UIKit/UIKit.h>
#import "ADLSingletonState.h"


@protocol FilterDelegate;
@class ADLRestClient;

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

