/*
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
#import "ADLCloseButton.h"

typedef enum {
	HUDAnimationNone,
	HUDAnimationShowZoom,
	HUDAnimationHideZoom,
	HUDAnimationHideFadeOut
} HUDAnimation;

@protocol LGViewHUDDelegate;

/**
 A HUD that mimics the native one used in iOS (when you press volume up or down 
 on the iPhone for instance) and also provides some more features (some more animations
 + activity indicator support included.)
 */

@interface LGViewHUD : UIView {
	UIImage* image;
	UIImageView* imageView;
	UILabel* bottomLabel;
	UILabel* topLabel;
	UIView* backgroundView;
    
    ADLCloseButton* closeButton;
	NSTimeInterval displayDuration;
	NSTimer* displayTimer;
	BOOL activityIndicatorOn;
	UIActivityIndicatorView* activityIndicator;
    
    
}

/** The image displayed at the center of the HUD. Default is nil. */
@property (readwrite, strong) UIImage* image;
/** The top text of the HUD. Shortcut to the text of the topLabel property. */
@property (readwrite, strong) NSString* topText;
/** The bottom text of the HUD. Shortcut to the text of the bottomLabel property. */
@property (readwrite, strong) NSString* bottomText;
/** The top label of the HUD. (So that you can adjust its properties ...) */
@property (readonly) UILabel* topLabel;
/** The bottom label of the HUD. (So that you can adjust its properties ...) */
@property (readonly) UILabel* bottomLabel;
/** HUD display duration. Default is 2 sec. */
@property (readwrite) NSTimeInterval displayDuration;
/** Diplays a large white activity indicator instead of the image if set to YES. 
 Default is NO. */ 
@property (readwrite) BOOL activityIndicatorOn;
@property (strong, nonatomic) NSObject<LGViewHUDDelegate> *delegate;

/** Returns the default HUD singleton instance. */
+(LGViewHUD*) defaultHUD;

/** Shows the HUD and hides it after a delay equals to the displayDuration property value. 
 HUDAnimationNone is used by default. */
-(void) showInView:(UIView*)view;

/** Shows the HUD with the given animation and hides it after a delay equals to the displayDuration property value. */
-(void) showInView:(UIView *)view withAnimation:(HUDAnimation)animation;

/** Hides the HUD right now.
 You only need to invoke this one when the HUD is displayed with an activity indicator 
 because there's no auto hide in that case. */
-(void) hideWithAnimation:(HUDAnimation)animation;

@end

@protocol LGViewHUDDelegate<NSObject>
    -(void)shallDismissHUD:(LGViewHUD*)hud;
@end    
