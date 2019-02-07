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
#import <UIKit/UIKit.h>

#define kCatchWidth 180


@protocol RGFileCellDelegate;

// TODO : Change that with an UITableViewRowAction, when iOS7 support will be abandoned
@interface RGFileCell : UITableViewCell <UIScrollViewDelegate>

@property (strong, nonatomic) UILabel *dossierTitleLabel;
@property (strong, nonatomic) UILabel *typologyLabel;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIView *retardPlaceHolder;
@property (strong, nonatomic) UIView *buttonsView;
@property (strong, nonatomic) UIButton *validateButton;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIView *contentCellView;
@property (strong, nonatomic) UISwitch *switchButton;

@property (weak) id<RGFileCellDelegate> delegate;
@property(nonatomic, readonly, weak) NSIndexPath* indexPath;
@property(nonatomic, readonly, weak) UITableView* tableView;


-(void) hideMenuOptions;

-(void) flickerSelection;

@end


@protocol RGFileCellDelegate <NSObject>

@optional

-(void)cell:(RGFileCell*)cell didSelectAtIndexPath:(NSIndexPath*)indexPath;

-(void)cell:(RGFileCell*)cell didCheckAtIndexPath:(NSIndexPath*)indexPath;

-(void)cell:(RGFileCell*)cell didTouchSecondaryButtonAtIndexPath:(NSIndexPath*)indexPath;

-(void)cell:(RGFileCell*)cell didTouchMainButtonAtIndexPath:(NSIndexPath*)indexPath;

-(BOOL)canSelectCell:(RGFileCell*) cell;

-(BOOL)canSwipeCell:(RGFileCell*) cell;

-(void)willSwipeCell:(RGFileCell*) cell;

-(void)willSelectCell:(RGFileCell*) cell;

@end
