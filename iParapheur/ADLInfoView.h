//
//  ADLInfoView.h
//  iParapheur
//
//  Created by Jason MAIRE on 25/01/2014.
//
//

#import <UIKit/UIKit.h>
#import "ADLAnnotation.h"

@interface ADLInfoView : UIView

@property (strong, nonatomic) UILabel *author;
@property (strong, nonatomic) UILabel *date;
@property (strong, nonatomic) UILabel *info;

@property (nonatomic, strong) ADLAnnotation *annotationModel;

@end
