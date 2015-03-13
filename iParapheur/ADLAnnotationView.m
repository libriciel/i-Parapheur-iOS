/*
 * Version 1.1
 * CeCILL Copyright (c) 2012, SKROBS, ADULLACT-projet
 * Initiated by ADULLACT-projet S.A.
 * Developped by SKROBS
 *
 * contact@adullact-projet.coop
 *
 * Ce logiciel est un programme informatique servant à faire circuler des
 * documents au travers d'un circuit de validation, où chaque acteur vise
 * le dossier, jusqu'à l'étape finale de signature.
 *
 * Ce logiciel est régi par la licence CeCILL soumise au droit français et
 * respectant les principes de diffusion des logiciels libres. Vous pouvez
 * utiliser, modifier et/ou redistribuer ce programme sous les conditions
 * de la licence CeCILL telle que diffusée par le CEA, le CNRS et l'INRIA
 * sur le site "http://www.cecill.info".
 *
 * En contrepartie de l'accessibilité au code source et des droits de copie,
 * de modification et de redistribution accordés par cette licence, il n'est
 * offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
 * seule une responsabilité restreinte pèse sur l'auteur du programme,  le
 * titulaire des droits patrimoniaux et les concédants successifs.
 *
 * A cet égard  l'attention de l'utilisateur est attirée sur les risques
 * associés au chargement,  à l'utilisation,  à la modification et/ou au
 * développement et à la reproduction du logiciel par l'utilisateur étant
 * donné sa spécificité de logiciel libre, qui peut le rendre complexe à
 * manipuler et qui le réserve donc à des développeurs et des professionnels
 * avertis possédant  des  connaissances  informatiques approfondies.  Les
 * utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
 * logiciel à leurs besoins dans des conditions permettant d'assurer la
 * sécurité de leurs systèmes et ou de leurs données et, plus généralement,
 * à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.
 *
 * Le fait que vous puissiez accéder à cet en-tête signifie que vous avez
 * pris connaissance de la licence CeCILL, et que vous en avez accepté les
 * termes.
 */

//
//  ADLAnnotationView.m
//  testDrawing
//

#import "ADLAnnotationView.h"
#import "UIColor+CustomColors.h"

#define SHOW_RULES 0


@implementation ADLAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        self.clearsContextBeforeDrawing = NO;
        self.contentMode = UIViewContentModeRedraw;
        self.autoresizingMask = UIViewAutoresizingNone;
        self.backgroundColor = [UIColor clearColor];
        
        _annotationModel = [[ADLAnnotation alloc] init];
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

-(void) setFrame:(CGRect)frame {
	
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

- (void) addButtons {
    /* Cut here to disable _close button */
    CGRect buttonFrame = self.frame;
    
    buttonFrame.origin.x = 0;
    buttonFrame.origin.y = 0;
    buttonFrame.size.width = kFingerSize;
    buttonFrame.size.height = kFingerSize;
    if (self.annotationModel.editable) {
        // CLOSE BUTTON
        self.closeButton = [[ADLAnnotationButton alloc] initWithFrame:buttonFrame];
        [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonHitted) forControlEvents:UIControlEventTouchUpInside];
        [self.closeButton setHidden:YES];
        [self.closeButton setNeedsDisplay];
    }
    // INFO BUTTON
    buttonFrame.origin.y = CGRectGetHeight(self.frame) - buttonFrame.size.height;
    self.infoButton = [[ADLAnnotationButton alloc] initWithFrame:buttonFrame];
    [self.infoButton setTitle:@"i" forState:UIControlStateNormal];
    [self.infoButton addTarget:self action:@selector(infoButtonHitted) forControlEvents:UIControlEventTouchUpInside];
    [self.infoButton setHidden:YES];
    [self.infoButton setNeedsDisplay];
    
    //POST IT BUTTON
    buttonFrame.origin.x = CGRectGetWidth(self.frame) - buttonFrame.size.width;
    buttonFrame.origin.y = 0.0f;
    CGRect postitFrame = buttonFrame;
    self.postItButton = [[ADLAnnotationButton alloc] initWithFrame:postitFrame];
    [self.postItButton setTitle:@"Aa" forState:UIControlStateNormal];
    [self.postItButton addTarget:self action:@selector(postItButtonHitted) forControlEvents:UIControlEventTouchUpInside];
    [self.postItButton setHidden:YES];
    
    
    [self addSubview:self.closeButton];
    [self addSubview:self.infoButton];
    [self addSubview:self.postItButton];

}

-(void)setSelected:(BOOL)selected {
    _selected = selected;
    [self.closeButton setHidden:!_selected];
    [self.postItButton setHidden:!_selected];
    [self.infoButton setHidden:!_selected];
    [self setNeedsDisplay];

    if ((self.postItView) && !_selected) {
        [self.postItView setHidden:YES];
        [self.postItView removeFromSuperview];
        if (self.annotationModel.editable) {
            [((ADLDrawingView*)[self superview]) updateAnnotation:_annotationModel];
        }
        self.postItView = nil;
    }
    if ((self.infoView) && !_selected) {
        [self.infoView setHidden:YES];
        [self.infoView removeFromSuperview];
        self.infoView = nil;
    }
}

-(BOOL)isResizing {
    return !CGPointEqualToPoint(self.anchor, CGPointZero);
}

/* notify when removed */

- (void) closeButtonHitted {
    if ([self.annotationModel uuid] != nil) {
        [self.drawingView removeAnnotation:_annotationModel];
    }
    [self removeFromSuperview];
}


- (void) infoButtonHitted {

	if (!self.infoView) {
        CGRect clippedFrame = [self.drawingView clipRectInView:CGRectMake(CGRectGetMinX(self.frame),CGRectGetMaxY(self.frame),kInfoWidth, kInfoHeight)];
        
        _infoView = [[ADLInfoView alloc] initWithFrame:clippedFrame];
        [_infoView setAnnotationModel:_annotationModel];
        [self.infoView setContentScaleFactor:[self contentScaleFactor]];
        [[self superview] addSubview:self.infoView];
    }
}


- (void) postItButtonHitted {
	
    if (!self.postItView) {
        CGRect clippedFrame = [self.drawingView clipRectInView:CGRectMake(CGRectGetMaxX(self.frame),CGRectGetMinY(self.frame),kPostItWidth, kPostItheight)];
        
        self.postItView = [[ADLPostItView alloc] initWithFrame:clippedFrame];
        self.postItView.userInteractionEnabled = self.annotationModel.editable;
        [self.postItView setAnnotationModel: [self annotationModel]];
        [self.postItView setContentScaleFactor:[self contentScaleFactor]];
        [[self superview] addSubview:self.postItView];
    }
}

// Override setContetScaleFactor to apply it to the close button;
-(void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    [super setContentScaleFactor:contentScaleFactor];
    [self.closeButton setContentScaleFactor:contentScaleFactor];
    [self.postItButton setContentScaleFactor:contentScaleFactor];
}


-(void)drawHandle {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
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


-(CGFloat)distanceBetween:(CGPoint)p and:(CGPoint)q {
    CGFloat dx = q.x - p.x;
    CGFloat dy = q.y - p.y;
    return sqrtf(dx*dx + dy*dy);
}


-(CGPoint)anchorForTouchLocation:(CGPoint) touchPoint {
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


- (void) handleTouchInside {
	[_postItView removeFromSuperview];
    _postItView = nil;
    [_infoView removeFromSuperview];
    _infoView = nil;
}



@end
