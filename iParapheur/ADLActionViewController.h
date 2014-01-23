//
//  ADLActoinViewController.h
//  iParapheur
//
//  Created by Emmanuel Peralta on 13/10/12.
//
//

#import <UIKit/UIKit.h>

@interface ADLActionViewController : UITableViewController
@property (nonatomic, assign) BOOL signatureEnabled;
@property (nonatomic, assign) BOOL visaEnabled;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) NSMutableArray *labels;

@end
