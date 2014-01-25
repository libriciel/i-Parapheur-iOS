//
//  ADLAnnotation.h
//  iParapheur
//
//  Created by Emmanuel Peralta on 09/10/12.
//
//

#import <Foundation/Foundation.h>

@interface ADLAnnotation : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic) BOOL editable;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *author;
// TODO
@property (nonatomic, strong) NSString *date;
@property (nonatomic) CGRect rect;


- (id)init;
- (id)initWithAnnotationDict:(NSDictionary*)annotation;
- (NSDictionary*)dict;

@end
