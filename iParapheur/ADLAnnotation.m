//
//  ADLAnnotation.m
//  iParapheur
//
//  Created by Emmanuel Peralta on 09/10/12.
//
//

#import "ADLAnnotation.h"
#import "ADLRestClient.h"

@implementation ADLAnnotation

-(id) init {
    if ((self = [super init])) {
        _author = @"";
        _uuid = @"";
        _rect = CGRectZero;
        _text = @"";
        _editable = YES;
    }
    return self;
}

-(id) initWithAnnotationDict:(NSDictionary *)annotation {
	
    if (self = [super init]) {
		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3)
			_uuid = annotation[@"id"];
		else
			_uuid = annotation[@"uuid"];

        _author = annotation[@"author"];
        _rect = [self rectWithDict:annotation[@"rect"]];
        
        _editable = ((NSString *) annotation[@"editable"]).boolValue;
        _text = annotation[@"text"];
    }
	
    return self;
}

/* compute the rect with pixels coordinates */
-(CGRect)rectWithDict:(NSDictionary*)dict {
    NSDictionary *topLeft = dict[@"topLeft"];
    NSDictionary *bottomRight = dict[@"bottomRight"];
    
    NSNumber *x = topLeft[@"x"];
    NSNumber *y = topLeft[@"y"];
    
    NSNumber *x1 = bottomRight[@"x"];
    NSNumber *y1 = bottomRight[@"y"];
    
    CGRect arect = CGRectMake(x.floatValue / 150.0f * 72.0f,
                      y.floatValue / 150.0f * 72.0f,
                      (x1.floatValue / 150.0f * 72.0f) - (x.floatValue / 150.0f * 72.0f), // width
                      (y1.floatValue / 150.0f * 72.0f) - (y.floatValue / 150.0f * 72.0f)); // height
    
    return CGRectInset(arect, -14.0f, -14.0f);
    
}

-(NSDictionary*) dictWithRect:(CGRect) rect {
    CGRect realRect = CGRectInset(rect, 14.0f, 14.0f);
    
    NSMutableDictionary *rectDict = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *topLeft = [[NSMutableDictionary alloc] init];
    topLeft[@"x"] = @(realRect.origin.x / 72.0f * 150.0f);
    topLeft[@"y"] = @(realRect.origin.y / 72.0f * 150.0f);
    
    NSMutableDictionary *bottomRight = [[NSMutableDictionary alloc] init];
    bottomRight[@"x"] = @(CGRectGetMaxX(realRect) / 72.0f * 150.0f);
    bottomRight[@"y"] = @(CGRectGetMaxY(realRect) / 72.0f * 150.0f);
    
    rectDict[@"topLeft"] = topLeft;
    rectDict[@"bottomRight"] = bottomRight;

    return rectDict;
}

-(NSDictionary*) dict {
    NSMutableDictionary *annotation = [[NSMutableDictionary alloc] init];
    
    if (_uuid != nil)
        annotation[@"uuid"] = _uuid;

    annotation[@"rect"] = [self dictWithRect:_rect];
    annotation[@"text"] = _text;
    annotation[@"type"] = @"rect";
    
    return annotation;
}

@end
