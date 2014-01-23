//
//  RGFilterViewController.h
//  iParapheur
//
//  Created by Jason MAIRE on 16/01/2014.
//
//

#import <UIKit/UIKit.h>
#import "ADLSingletonState.h"
#import "ADLParapheurWallDelegateProtocol.h"

@protocol FilterDelegate;
//@protocol FilterDataSource;

@interface ADLFilterViewController : UIViewController
    <UITableViewDataSource,
    UITableViewDelegate,
    UIPickerViewDataSource,
    UIPickerViewDelegate,
    UIPopoverControllerDelegate,
    ADLParapheurWallDelegateProtocol>

@property (weak) id <FilterDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITextField *titreTextField;
@property (strong, nonatomic) IBOutlet UITableView *typesTableView;
@property (strong, nonatomic) IBOutlet UIButton *banetteButton;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

// Picker pour le choix des banettes, présent dans le popover en dessous.
@property (strong, nonatomic) UIPickerView *banettePicker;
@property (strong, nonatomic) UIPopoverController *pickerPopover;

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

