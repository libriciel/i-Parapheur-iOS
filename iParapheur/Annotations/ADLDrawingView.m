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
#import "ADLDrawingView.h"
#import "DeviceUtils.h"


#define _UIKeyboardFrameEndUserInfoKey (&UIKeyboardFrameEndUserInfoKey != NULL ? UIKeyboardFrameEndUserInfoKey : @"UIKeyboardBoundsUserInfoKey")


@implementation ADLDrawingView


- (id)initWithFrame:(CGRect)frame {

	// NSLog(@"ADLDrawingView initWithFrame %p", self);
	
	self = [super initWithFrame:frame];

	if (self) {
		_hittedView = nil;
		_currentAnnotView = nil;

		// DoubleTabGestureRecogniser

		UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
		                                                                                             action:@selector(handleDoubleTap:)];
		doubleTapGestureRecognizer.numberOfTapsRequired = 2;

		UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
		                                                                                             action:@selector(handleSingleTap:)];
		singleTapGestureRecognizer.numberOfTouchesRequired = 1;
		singleTapGestureRecognizer.numberOfTapsRequired = 1;

		[self addGestureRecognizer:singleTapGestureRecognizer];
		[self addGestureRecognizer:doubleTapGestureRecognizer];

		[singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer]; // Single tap requires double tap to fail

		// LongPressGestureRecogniser

		_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
		                                                                            action:@selector(handleLongPress:)];

		_longPressGestureRecognizer.cancelsTouchesInView = NO;

		[self addGestureRecognizer:_longPressGestureRecognizer];

		// by default disable annotations

		_enabled = YES;
		_shallUpdateCurrent = NO;

		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(keyboardWillShow:)
				                                     name:UIKeyboardWillShowNotification
				                                   object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(keyboardWillHide:)
				                                     name:UIKeyboardWillHideNotification
				                                   object:nil];
	}
	
	return self;
}


- (void)removeFromSuperview {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super removeFromSuperview];
}


-(void)dealloc {
	for (UIView *a in [self subviews]) {
		[a removeFromSuperview];
	}
}


- (void)awakeFromNib {

	_hittedView = nil;
	_currentAnnotView = nil;
}


- (CGFloat)idealOffsetForView:(UIView *)view
                    withSpace:(CGFloat)space {

	// Convert the rect to get the view's distance from the top of the scrollView.
	CGRect rect = [view convertRect:view.bounds
	                         toView:self.superScrollView];

	// Set starting offset to that point
	CGFloat offset = rect.origin.y - (space / 2.0f) + (rect.size.height / 2.0f);


	/*
	if ( self.superScrollView.contentSize.height - offset < space ) {
		// Scroll to the bottom
		offset = self.superScrollView.contentSize.height - space;
	} else {
		if ( view.bounds.size.height < space ) {
			// Center vertically if there's room
			offset -= floor((space-view.bounds.size.height)/2.0);
		}
		if ( offset + space > self.superScrollView.contentSize.height ) {
			// Clamp to content size
			offset = self.superScrollView.contentSize.height - space;
		}
	}*/

	if (offset < 0) offset = 0;

	return offset;
}


- (UIView *)findFirstResponderBeneathView:(UIView *)view {
	// Search recursively for first responder
	for (UIView *childView in view.subviews) {
		if ([childView respondsToSelector:@selector(isFirstResponder)] && childView.isFirstResponder) return childView;
		UIView *result = [self findFirstResponderBeneathView:childView];
		if (result) return result;
	}
	return nil;
}


- (void)keyboardWillShow:(NSNotification *)notification {

	_keyboardRect = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
	_keyboardVisible = YES;

	UIView *firstResponder = [self findFirstResponderBeneathView:self];
	if (!firstResponder) {
		// No child view is the first responder - nothing to do here
		return;
	}

	/*
	if (!_priorInsetSaved) {
		_priorInset = self.contentInset;
		_priorInsetSaved = YES;
	}*/

	// Shrink view's inset by the keyboard's height, and scroll to show the text field/view being edited
	[UIView beginAnimations:nil
	                context:NULL];
	[UIView setAnimationCurve:(UIViewAnimationCurve) [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
	[UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue]];

	self.contentInset = self.contentInsetForKeyboard;

	[self.superScrollView setContentOffset:CGPointMake(self.superScrollView.contentOffset.x, [self idealOffsetForView:firstResponder
	                                                                                                        withSpace:self.keyboardRect.size.width])
	                              animated:YES];

	[[self parentScrollView] setScrollIndicatorInsets:_contentInset];

	[UIView commitAnimations];
}


- (void)keyboardWillHide:(NSNotification *)notification {

	_keyboardRect = CGRectZero;
	_keyboardVisible = NO;

	// Restore dimensions to prior size

	[UIView beginAnimations:nil
	                context:NULL];

	[UIView setAnimationCurve:(UIViewAnimationCurve) [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
	[UIView setAnimationDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue]];
	//_contentInset = _priorInset;
	_contentOffset = CGPointZero;
	[[self parentScrollView] setScrollIndicatorInsets:_contentInset];
	//_priorInsetSaved = NO;
	[UIView commitAnimations];
}


- (UIEdgeInsets)contentInsetForKeyboard {

	UIEdgeInsets newInset = _contentInset;
	CGRect keyboardRect = [self keyboardRect];
	newInset.bottom = keyboardRect.size.height - ((keyboardRect.origin.y + keyboardRect.size.height) - (self.bounds.origin.y + self.bounds.size.height));
	return newInset;
}


- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {

	if ([_masterViewController getMainPageBar].alpha == 0)
		[[_masterViewController getMainPageBar] showPagebar];
	else
		[[_masterViewController getMainPageBar] hidePagebar];
}


- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {

	if ([DeviceUtils isConnectedToDemoAccount]) {
		[ViewUtils logInfoMessage:@"L'ajout d'annotations est désactivé sur le parapheur de démonstration."
		                    title:@"Action indisponible"
		           viewController:nil];
		return;
	}
	
	if (!_hittedView && _enabled) {
		CGPoint touchPoint = [gestureRecognizer locationInView:self];
		CGRect annotFrame = [self clipRectInView:CGRectMake(touchPoint.x, touchPoint.y, kAnnotationMinHeight, kAnnotationMinWidth)];
		_currentAnnotView = [[ADLAnnotationView alloc] initWithFrame:annotFrame];
		[_currentAnnotView setContentScaleFactor:[_parentScrollView contentScaleFactor]];

		[(ADLAnnotationView *) _currentAnnotView refreshModel];

		[self addAnnotation:[(ADLAnnotationView *) _currentAnnotView annotationModel]];

		[self addSubview:_currentAnnotView];
	}
}


- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
	//[super setContentScaleFactor:contentScaleFactor];
	for (UIView *subview in self.subviews) {
		[subview setContentScaleFactor:contentScaleFactor];
	}
}


- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {

	CGPoint touchPoint = [gestureRecognizer locationInView:self];

	if (_hittedView && _enabled && _hittedView.annotationModel.unwrappedEditable) {
		[self animateviewOnLongPressGesture:touchPoint];
		_hasBeenLongPressed = YES;
	}
}


- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event {

	if (_enabled) {

		UITouch *touch = [event allTouches].anyObject;

		CGPoint touchPoint = [self clipPointToView:[touch locationInView:self]];

		UIView *hitted = [self hitTest:touchPoint
		                     withEvent:event];

		if ([hitted isKindOfClass:[ADLAnnotationView class]] || [hitted isKindOfClass:[ADLDrawingView class]]) {

			[self unselectAnnotations];
			_hittedView = nil;

			if (hitted != self) {

				[(ADLAnnotationView *) hitted handleTouchInside];

				_parentScrollView.scrollEnabled = NO;
				_superScrollView.scrollEnabled = NO;
				_hittedView = (ADLAnnotationView *) hitted;
				_origin = hitted.frame.origin;
				_dx = (CGFloat) sqrt(pow(_origin.x - touchPoint.x, 2.0));
				_dy = (CGFloat) sqrt(pow(_origin.y - touchPoint.y, 2.0));
				_currentAnnotView = nil;

				if ([_hittedView isInHandle:[touch locationInView:self]]) {
					_longPressGestureRecognizer.enabled = NO;
				}

				_hittedView.selected = true;
				[_hittedView setNeedsDisplay];
			}
			else {
				_parentScrollView.scrollEnabled = YES;
				_superScrollView.scrollEnabled = YES;
				_hasBeenLongPressed = NO;
			}
		}
	}
}


- (void)unselectAnnotations {

	for (UIView *subview in [self subviews]) {
		if ([subview class] == [ADLAnnotationView class]) {
			ADLAnnotationView *a = (ADLAnnotationView *) subview;
			[a setSelected:NO];
		}
	}
}


- (void)displayAnnotations:(NSArray *)annotations {

	ADLAnnotationView *annotView = nil;
	for (NSDictionary *dict in annotations) {
		CGRect annotRect;
		annotView = [[ADLAnnotationView alloc] initWithFrame:annotRect];
		[self addSubview:annotView];
	}
}


- (CGRect)convertFromPixelRect:(CGRect)pixelRect {

	return CGRectZero;
}


- (CGRect)convertToPixelRect:(CGRect)uiViewRect {

	return CGRectZero;
}


- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event {

	if (_enabled) {
		UITouch *touch = [touches anyObject];

		if ([_hittedView isKindOfClass:[ADLAnnotationView class]] || [_hittedView isKindOfClass:[ADLDrawingView class]]) {
			CGPoint point = [self clipPointToView:[touch locationInView:self]];
			if (_hittedView.annotationModel.unwrappedEditable) {
				if ([_hittedView isInHandle:[touch locationInView:self]]) {

					CGRect frame = _hittedView.frame;

					frame.size.width = point.x - frame.origin.x;
					frame.size.height = point.y - frame.origin.y;
					_parentScrollView.scrollEnabled = NO;
					_superScrollView.scrollEnabled = NO;
					_shallUpdateCurrent = YES;

					_hittedView.frame = frame;
					[_hittedView setNeedsDisplay];
				}
				else if (_hittedView && _hasBeenLongPressed) {
					CGRect frame = _hittedView.frame;

					frame.origin.x = point.x - _dx;
					frame.origin.y = point.y - _dy;

					frame = [self clipRectInView:frame];

					_parentScrollView.scrollEnabled = NO;
					_superScrollView.scrollEnabled = NO;
					_shallUpdateCurrent = YES;
					_hittedView.frame = frame;
				}
			}

			[self touchesCancelled:touches
			             withEvent:event];
		}
	}

}


- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event {

	if (_enabled) {

		UITouch *touch = touches.anyObject;

		if (_hasBeenLongPressed) {
			_hasBeenLongPressed = NO;
			[self unanimateView:[touch locationInView:self]];
		}

		if (_hittedView != nil && [_hittedView isKindOfClass:[ADLAnnotationView class]] && _shallUpdateCurrent) {

			[_hittedView refreshModel];
			Annotation *annotation = _hittedView.annotationModel;

			if (_hittedView.annotationModel.unwrappedId && _hittedView.annotationModel.unwrappedEditable)
				[self updateAnnotation:annotation];
		}

		//_hittedView = nil;
		_parentScrollView.scrollEnabled = YES;
		_superScrollView.scrollEnabled = YES;
		_longPressGestureRecognizer.enabled = YES;

		_shallUpdateCurrent = NO;
	}

}


- (CGPoint)clipPointToView:(CGPoint)touch {

	CGPoint ret = touch;

	if (touch.x < 0)
		ret.x = 0;

	if (touch.x > self.frame.size.width)
		ret.x = self.frame.size.width;

	if (touch.y < 0)
		ret.y = 0;

	if (touch.y > self.frame.size.height)
		ret.y = self.frame.size.height;

	return ret;


}


- (CGRect)clipRectInView:(CGRect)rect {

	CGRect frame = self.frame;
	CGRect clippedRect = rect;

	CGFloat dx = 0.0f;
	CGFloat dy = 0.0f;

	if (CGRectGetMaxX(rect) > CGRectGetMaxX(frame)) {
		// overflow
		dx = CGRectGetMaxX(rect) - CGRectGetMaxX(frame);
	}


	if (CGRectGetMaxY(rect) > CGRectGetMaxY(frame)) {
		dy = CGRectGetMaxY(rect) - CGRectGetMaxY(frame);
	}

	clippedRect.origin.x -= dx;
	clippedRect.origin.y -= dy;

	clippedRect.origin = [self clipPointToView:clippedRect.origin];
	return clippedRect;
}


- (void)animateviewOnLongPressGesture:(CGPoint)touchPoint {

#define GROW_ANIMATION_DURATION_SECONDS 0.15

	NSValue *touchPointValue = [NSValue valueWithCGPoint:touchPoint];
	[UIView beginAnimations:nil
	                context:(__bridge void *) (touchPointValue)];
	[UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
	[UIView setAnimationDelegate:self];
	//[UIView setAnimationDidStopSelector:@selector(growAnimationDidStop:finished:context:)];
	CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
	_hittedView.transform = transform;
	[UIView commitAnimations];

}


- (void)unanimateView:(CGPoint)touchPoint {

#define MOVE_ANIMATION_DURATION_SECONDS 0.15

	[UIView beginAnimations:nil
	                context:NULL];

	[UIView setAnimationDuration:MOVE_ANIMATION_DURATION_SECONDS];
	_hittedView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
	/*
	 Move the placardView to under the touch.
	 We passed the location wrapped in an NSValue as the context.
	 Get the point from the value, then release the value because we retained it in touchesBegan:withEvent:.
	 */
	//_hittedView.center = touchPoint;
	[UIView commitAnimations];
}


#pragma mark - dataSource


- (void)refreshAnnotations {
	
	for (UIView *a in [self subviews]) {
		[a removeFromSuperview];
	}

	if (_masterViewController.dataSource != nil) {
		NSArray *annotations = [self annotationsForPage:_pageNumber];

		for (Annotation *annotation in annotations) {
			ADLAnnotationView *a = [[ADLAnnotationView alloc] initWithAnnotation:annotation];
			a.drawingView = self;
			[self addSubview:a];
		}
	}
}


- (void)updateAnnotation:(Annotation *)annotation {

	[annotation setUnwrappedPage:@(_pageNumber)];
	[_masterViewController.dataSource updateAnnotation:annotation];
}


- (void)addAnnotation:(Annotation *)annotation {

	[annotation setUnwrappedPage:@(_pageNumber)];
	[_masterViewController.dataSource addAnnotation:annotation];
}


- (void)removeAnnotation:(Annotation *)annotation {

	[_masterViewController.dataSource removeAnnotation:annotation];
}


- (NSArray *)annotationsForPage:(NSUInteger)page {

	if (_enabled) if ([_masterViewController.dataSource respondsToSelector:@selector(annotationsForPage:)])
		return [_masterViewController.dataSource annotationsForPage:page];

	return nil;
}


#pragma mark - Abstract Method


- (CGSize)getPageSize {

	@throw [NSException exceptionWithName:NSInternalInconsistencyException
	                               reason:[NSString stringWithFormat:@"You must override %@ in a subclass",
	                                                                 NSStringFromSelector(_cmd)]
		                         userInfo:nil];
}


@end
