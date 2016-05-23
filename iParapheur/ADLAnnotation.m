/*
 * Copyright 2012-2016, Adullact-Projet.
 *
 * contact@adullact-projet.coop
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
		if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue ] >= 3)
			_uuid = annotation[@"id"];
		else
			_uuid = annotation[@"uuid"];

        _author = annotation[@"author"];
        _rect = [self rectWithDict:annotation[@"rect"]];
        
        _editable = [(NSString *) annotation[@"editable"] boolValue];
        _text = annotation[@"text"];
    }
	
    return self;
}

/* compute the rect with pixels coordoniates */
-(CGRect)rectWithDict:(NSDictionary*)dict {
    NSDictionary *topLeft = dict[@"topLeft"];
    NSDictionary *bottomRight = dict[@"bottomRight"];
    
    NSNumber *x = topLeft[@"x"];
    NSNumber *y = topLeft[@"y"];
    
    NSNumber *x1 = bottomRight[@"x"];
    NSNumber *y1 = bottomRight[@"y"];
    
    CGRect arect = CGRectMake([x floatValue]  / 150.0f * 72.0f,
                      [y floatValue]  / 150.0f * 72.0f,
                      ([x1 floatValue]  / 150.0f * 72.0f) - ([x floatValue] / 150.0f * 72.0f), // width
                      ([y1 floatValue] / 150.0f * 72.0f) - ([y floatValue] / 150.0f * 72.0f)); // height
    
    return CGRectInset(arect, -14.0f, -14.0f);
}

-(NSDictionary*) dictWithRect:(CGRect) rect {
    CGRect realRect = CGRectInset(rect, 14.0f, 14.0f);
    
    NSMutableDictionary *rectDict = [NSMutableDictionary new];
    
    NSMutableDictionary *topLeft = [NSMutableDictionary new];
    topLeft[@"x"] = @(realRect.origin.x / 72.0f * 150.0f);
    topLeft[@"y"] = @(realRect.origin.y / 72.0f * 150.0f);
    
    NSMutableDictionary *bottomRight = [NSMutableDictionary new];
    bottomRight[@"x"] = @(CGRectGetMaxX(realRect) / 72.0f * 150.0f);
    bottomRight[@"y"] = @(CGRectGetMaxY(realRect) / 72.0f * 150.0f);
    
    rectDict[@"topLeft"] = topLeft;
    rectDict[@"bottomRight"] = bottomRight;
    
    return rectDict;
}

-(NSDictionary*) dict {
    NSMutableDictionary *annotation = [NSMutableDictionary new];
    
    if (_uuid != nil)
        annotation[@"uuid"] = _uuid;

    annotation[@"rect"] = [self dictWithRect:_rect];
    annotation[@"text"] = _text;
    annotation[@"type"] = @"rect";

    return annotation;
}

@end
