//
//  ADLPostItView.h
//  iParapheur
//
//  Created by Emmanuel Peralta on 08/10/12.
//
//

#import <UIKit/UIKit.h>
#import "ADLAnnotation.h"

@interface ADLPostItView : UIView<UITextViewDelegate>

@property (nonatomic, strong) ADLAnnotation *annotationModel;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UITextView *textView;
@end
