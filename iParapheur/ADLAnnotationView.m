/*
 * Copyright 2012-2016, Adullact-Projet.
 * Contributors : SKROBS (2012)
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
#import "ADLAnnotationView.h"
#import "UIColor+CustomColors.h"

#define SHOW_RULES 0


@implementation ADLAnnotationView


-(id)initWithFrame:(CGRect)frame {
	
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        self.clearsContextBeforeDrawing = NO;
        self.contentMode = UIViewContentModeRedraw;
        self.autoresizingMask = UIViewAutoresizingNone;
        self.backgroundColor = [UIColor clearColor];
        
        _annotationModel = [ADLAnnotation new];
        _selected = NO;
        
        [self addButtons];

        
//disable the shadowlayer for now it's to consuming
#if 0
        if ([self.layer respondsToSelector:@selector(setShadowOffset:)])
			self.layer.shadowOffset = CGSizeMake(0.25, 0.25);
        
        if ([self.layer respondsToSelector:@selector(setShadowColor:)])
			self.layer.shadowColor = [[UIColor blackColor] CGColor];
        
		if ([self.layer respondsToSelector:@selector(setShadowRadius:)])
			self.layer.shadowRadius = 2;
        
		if ([self.layer respondsToSelector:@selector(setShadowOpacity:)])
			self.layer.shadowOpacity = 0.75;
#endif
    }
    return self;
}


-(void)setFrame:(CGRect)frame {
	
    if (frame.size.height < kAnnotationMinHeight) {
        frame.size.height = kAnnotationMinHeight;
    }
    if (frame.size.width < kAnnotationMinWidth) {
        frame.size.width = kAnnotationMinWidth;
    }
    
    [super setFrame:frame];
    // ATTENTION : on doit utiliser bounds et non frame pour les boutons pour
    // gérer l'augmentation du scale lors du déplacement (bounds n'est pas affecté par le scale)
    CGRect postitFrame = CGRectMake(CGRectGetWidth(self.bounds) - kFingerSize, 0.0f, kFingerSize ,kFingerSize);
    [self.postItButton setFrame:postitFrame];
    
    CGRect infoFrame = CGRectMake(0.0f, CGRectGetHeight(self.bounds) - kFingerSize, kFingerSize ,kFingerSize);
    [self.infoButton setFrame:infoFrame];
}


-(id)initWithAnnotation:(ADLAnnotation*)annotation {
	
	
    CGRect frame = [annotation rect];
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        self.clearsContextBeforeDrawing = NO;
        self.contentMode = UIViewContentModeRedraw;
        self.autoresizingMask = UIViewAutoresizingNone;
        self.backgroundColor = [UIColor clearColor];
        
        self.selected = NO;
        
        
        //disable the shadowlayer for now it's to consuming
#if 0
        if ([self.layer respondsToSelector:@selector(setShadowOffset:)])
			self.layer.shadowOffset = CGSizeMake(0.25, 0.25);
        
        if ([self.layer respondsToSelector:@selector(setShadowColor:)])
			self.layer.shadowColor = [[UIColor blackColor] CGColor];
        
		if ([self.layer respondsToSelector:@selector(setShadowRadius:)])
			self.layer.shadowRadius = 2;
        
		if ([self.layer respondsToSelector:@selector(setShadowOpacity:)])
			self.layer.shadowOpacity = 0.75;
#endif
        
        self.annotationModel = annotation;
        
        if ([self.annotationModel text] != nil && ![[self.annotationModel text] isEqualToString:@""]) {
            //[self.postItButton setHasText:YES];
        }
        [self addButtons];
        
    }
    return self;
}


-(void)addButtons {
    /* Cut here to disable _close button */
    CGRect buttonFrame = self.frame;
    
    buttonFrame.origin.x = 0;
    buttonFrame.origin.y = 0;
    buttonFrame.size.width = kFingerSize;
    buttonFrame.size.height = kFingerSize;
    if (_annotationModel.editable) {
        // CLOSE BUTTON
        _closeButton = [[ADLAnnotationButton alloc] initWithFrame:buttonFrame];
        [_closeButton setTitle:@"X" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonHitted) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setHidden:YES];
        [_closeButton setNeedsDisplay];
    }
    // INFO BUTTON
    buttonFrame.origin.y = CGRectGetHeight(self.frame) - buttonFrame.size.height;
    _infoButton = [[ADLAnnotationButton alloc] initWithFrame:buttonFrame];
    [_infoButton setTitle:@"i" forState:UIControlStateNormal];
    [_infoButton addTarget:self action:@selector(infoButtonHitted) forControlEvents:UIControlEventTouchUpInside];
    [_infoButton setHidden:YES];
    [_infoButton setNeedsDisplay];
    
    //POST IT BUTTON
    buttonFrame.origin.x = CGRectGetWidth(self.frame) - buttonFrame.size.width;
    buttonFrame.origin.y = 0.0f;
    CGRect postitFrame = buttonFrame;
    _postItButton = [[ADLAnnotationButton alloc] initWithFrame:postitFrame];
    [_postItButton setTitle:@"Aa" forState:UIControlStateNormal];
    [_postItButton addTarget:self action:@selector(postItButtonHitted) forControlEvents:UIControlEventTouchUpInside];
    [_postItButton setHidden:YES];
    
    
    [self addSubview:_closeButton];
    [self addSubview:_infoButton];
    [self addSubview:_postItButton];
}


-(void)setSelected:(BOOL)selected {
    _selected = selected;
    [_closeButton setHidden:!_selected];
    [_postItButton setHidden:!_selected];
    [_infoButton setHidden:!_selected];
    [self setNeedsDisplay];

    if ((_postItView) && !_selected) {
        [_postItView setHidden:YES];
        [_postItView removeFromSuperview];
        if (_annotationModel.editable) {
            [_drawingView updateAnnotation:_annotationModel];
        }
        _postItView = nil;
    }
    if ((_infoView) && !_selected) {
        [_infoView setHidden:YES];
        [_infoView removeFromSuperview];
        _infoView = nil;
    }
}


-(BOOL)isResizing {
    return !CGPointEqualToPoint(self.anchor, CGPointZero);
}


#pragma mark - Notifcation events


-(void)closeButtonHitted {
	
	if (_postItView) {
		[_postItView setHidden:YES];
		[_postItView removeFromSuperview];
		_postItView = nil;
	}
	
	if (_infoView) {
		[_infoView setHidden:YES];
		[_infoView removeFromSuperview];
		_infoView = nil;
	}
	
	if ([self.annotationModel uuid] != nil)
        [_drawingView removeAnnotation:_annotationModel];
	
	[self removeFromSuperview];
}


-(void)infoButtonHitted {

	if (!_infoView) {
        CGRect clippedFrame = [_drawingView clipRectInView:CGRectMake(CGRectGetMinX(self.frame),CGRectGetMaxY(self.frame),kInfoWidth, kInfoHeight)];
        
        _infoView = [[ADLInfoView alloc] initWithFrame:clippedFrame];
        _infoView.annotationModel = _annotationModel;
        _infoView.contentScaleFactor = self.contentScaleFactor;
        [[self superview] addSubview:_infoView];
    }
}


-(void)postItButtonHitted {
	
    if (!_postItView) {
	    CGRect clippedFrame = [_drawingView clipRectInView:CGRectMake(CGRectGetMaxX(self.frame),CGRectGetMinY(self.frame),kPostItWidth, kPostItheight)];
        _postItView = [[ADLPostItView alloc] initWithFrame:clippedFrame];
        _postItView.userInteractionEnabled = _annotationModel.editable;
        _postItView.annotationModel = _annotationModel;
        _postItView.contentScaleFactor = self.contentScaleFactor;
        [self.superview addSubview:_postItView];
    }
}


// Override setContetScaleFactor to apply it to the close button;
-(void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    super.contentScaleFactor = contentScaleFactor;
    self.closeButton.contentScaleFactor = contentScaleFactor;
    self.postItButton.contentScaleFactor = contentScaleFactor;
}


-(void)drawHandle {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
   
    
    if (self.annotationModel.editable) {
        CGContextSaveGState(context);
        UIGraphicsPushContext(context);
        {
            [[UIColor darkPurpleColor] setStroke];
            [[UIColor darkPurpleColor] setFill];
            CGContextSetLineWidth(context, 1.0f);
            
            CGFloat width = CGRectGetMaxX(self.bounds);
            CGFloat height = CGRectGetMaxY(self.bounds);
            
            CGPoint start1 = CGPointMake(width - 20.0f, height - 30.0f);
            CGPoint end1 = CGPointMake(width - 30.0f, height - 20.0f);
            
            CGPoint start2 = CGPointMake(width - 20.0f, height - 40.0f);
            CGPoint end2 = CGPointMake(width - 40.0f, height - 20.0f);
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, start1.x, start1.y);
            CGContextAddLineToPoint(context, end1.x, end1.y);
            CGContextStrokePath(context);
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, start2.x, start2.y);
            CGContextAddLineToPoint(context, end2.x, end2.y);
            CGContextStrokePath(context);
            
        }
        UIGraphicsPopContext();
        CGContextRestoreGState(context);
    }

    UIGraphicsPushContext(context);
    {
        CGRect rect = self.bounds;
        
#if SHOW_RULES
        [[UIColor darkRedColor] setStroke];
        
        CGContextStrokeRect(context, rect);
#endif
		
        CGRect annotRect = CGRectInset(rect, 12, 12);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:annotRect cornerRadius:10.0f];

        path.lineWidth = 4;
        
        [[UIColor darkYellowColor] setFill];

        [[UIColor darkPurpleColor] setStroke];
        [path stroke];
        
    }
    UIGraphicsPopContext();
    
}


-(CGFloat)distanceBetween:(CGPoint)p
					  and:(CGPoint)q {
	
    CGFloat dx = q.x - p.x;
    CGFloat dy = q.y - p.y;
    return sqrtf(dx*dx + dy*dy);
}


-(CGPoint)anchorForTouchLocation:(CGPoint)touchPoint {
    CGPoint bottomRight = CGPointMake(CGRectGetMaxX(self.frame) , CGRectGetMaxY(self.frame));

    if ([self distanceBetween:touchPoint and:bottomRight] < kFingerSize)
        return bottomRight;

    return CGPointZero;
}


// Used to detect resizing
-(BOOL)isInHandle:(CGPoint)touchPoint {
    CGPoint bottomRight = CGPointMake(CGRectGetMaxX(self.frame) , CGRectGetMaxY(self.frame));
    return [self distanceBetween:touchPoint and:bottomRight] < kFingerSize;
}


-(void)refreshModel {
    [_annotationModel setRect:self.frame];
}


-(void)handleTouchInside {
	[_postItView removeFromSuperview];
    _postItView = nil;
    [_infoView removeFromSuperview];
    _infoView = nil;
}



@end
