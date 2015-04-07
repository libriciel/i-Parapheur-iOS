//
//	ReaderMainPagebar.m
//	Reader v2.5.6
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderMainPagebar.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"

#import <QuartzCore/QuartzCore.h>


@interface ReaderMainPagebar ()

@property (nonatomic, readwrite, strong) ReaderDocument *document;
@property (nonatomic, readwrite, strong) ReaderTrackControl *trackControl;
@property (nonatomic, readwrite, strong) ReaderPagebarThumb *pageThumbView;
@property (nonatomic, readwrite, strong) NSMutableDictionary *miniThumbViews;
@property (nonatomic, readwrite, strong) UIView *pageNumberView;
@property (nonatomic, readwrite, strong) UILabel *pageNumberLabel;

@property (nonatomic, strong) NSTimer *enableTimer;
@property (nonatomic, strong) NSTimer *trackTimer;

@end


@implementation ReaderMainPagebar

#pragma mark Constants

#define THUMB_SMALL_GAP 2
#define THUMB_SMALL_WIDTH 22
#define THUMB_SMALL_HEIGHT 28

#define THUMB_LARGE_WIDTH 32
#define THUMB_LARGE_HEIGHT 42

#define PAGE_NUMBER_WIDTH 96.0f
#define PAGE_NUMBER_HEIGHT 30.0f
#define PAGE_NUMBER_SPACE 20.0f

#pragma mark Properties

@synthesize delegate;
@synthesize document, trackControl, pageThumbView,miniThumbViews, pageNumberLabel, pageNumberView;
@synthesize enableTimer, trackTimer;


+ (Class)layerClass
{
	return [CAGradientLayer class];
}


- (id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame document:nil];
}

- (void)updatePageThumbView:(NSInteger)page
{
	NSInteger pages = [document epPageCount];
	if (pages > 1) // Only update frame if more than one page
	{
		CGFloat controlWidth = trackControl.bounds.size.width;
		CGFloat useableWidth = (controlWidth - THUMB_LARGE_WIDTH);
		CGFloat stride = (useableWidth / (pages - 1)); // Page stride
		NSInteger X = (stride * (page - 1)); CGFloat pageThumbX = X;
		
		CGRect pageThumbRect = pageThumbView.frame; // Current frame
		if (pageThumbX != pageThumbRect.origin.x) // Only if different
		{
			pageThumbRect.origin.x = pageThumbX; // The new X position
			pageThumbView.frame = pageThumbRect; // Update the frame
		}
	}

	if (page != pageThumbView.tag) // Only if page number changed
	{
		pageThumbView.tag = page;
		[pageThumbView reuse]; // Reuse the thumb view
		
		CGSize size = CGSizeMake(THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT); // Maximum thumb size
		NSURL *fileURL = document.fileURL;
		NSString *guid = document.guid;
		NSString *phrase = document.password;
		
		ReaderThumbRequest *request = [ReaderThumbRequest forView:pageThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];
		UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:request priority:YES]; // Request the thumb
		UIImage *thumb = ([image isKindOfClass:[UIImage class]] ? image : nil);
		
		[pageThumbView showImage:thumb];
	}
}

- (void)updatePageNumberText:(NSInteger)page
{
	DXLog(@"");

	if (page != pageNumberLabel.tag) // Only if page number changed
	{
		NSInteger pages = [document epPageCount]; // Total pages
		NSString *format = @"%1$d de %2$d"; // Format
		NSString *number = [NSString stringWithFormat:format, page, pages]; // Text
		
		pageNumberLabel.text = number; // Update the page number label text
		pageNumberLabel.tag = page; // Update the last page number tag
	}
}

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object
{
	DXLog(@"");

	assert(object != nil); // Check

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = YES;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		self.backgroundColor = [UIColor clearColor];
		
		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *liteColor = [UIColor colorWithWhite:0.82f alpha:0.8f];
		UIColor *darkColor = [UIColor colorWithWhite:0.32f alpha:0.8f];
		layer.colors = [NSArray arrayWithObjects:(id)liteColor.CGColor, (id)darkColor.CGColor, nil];

		CGRect shadowRect = self.bounds; shadowRect.size.height = 4.0f; shadowRect.origin.y -= shadowRect.size.height;
		ReaderPagebarShadow *shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];
		[self addSubview:shadowView];
		
		// Page numbers view
		CGFloat numberY = (0.0f - (PAGE_NUMBER_HEIGHT + PAGE_NUMBER_SPACE));
		CGFloat numberX = ((self.bounds.size.width - PAGE_NUMBER_WIDTH) / 2.0f);
		CGRect numberRect = CGRectMake(numberX, numberY, PAGE_NUMBER_WIDTH, PAGE_NUMBER_HEIGHT);
		
		self.pageNumberView = [[UIView alloc] initWithFrame:numberRect];

		pageNumberView.autoresizesSubviews = NO;
		pageNumberView.userInteractionEnabled = NO;
		pageNumberView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		pageNumberView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];

		//pageNumberView.layer.cornerRadius = 4.0f;
		pageNumberView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
		pageNumberView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6f].CGColor;
		pageNumberView.layer.shadowPath = [UIBezierPath bezierPathWithRect:pageNumberView.bounds].CGPath;
		pageNumberView.layer.shadowRadius = 2.0f; pageNumberView.layer.shadowOpacity = 1.0f;
		
		// Page numbers label
		CGRect textRect = CGRectInset(pageNumberView.bounds, 4.0f, 2.0f); // Inset the text a bit
		self.pageNumberLabel = [[UILabel alloc] initWithFrame:textRect];

		pageNumberLabel.autoresizesSubviews = NO;
		pageNumberLabel.autoresizingMask = UIViewAutoresizingNone;
		pageNumberLabel.textAlignment = NSTextAlignmentCenter;
		pageNumberLabel.backgroundColor = [UIColor clearColor];
		pageNumberLabel.textColor = [UIColor whiteColor];
		pageNumberLabel.font = [UIFont systemFontOfSize:16.0f];
		pageNumberLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		pageNumberLabel.shadowColor = [UIColor blackColor];
		pageNumberLabel.adjustsFontSizeToFitWidth = YES;
		pageNumberLabel.minimumScaleFactor = 12.0f;

		[pageNumberView addSubview:pageNumberLabel]; // Add label view

		[self addSubview:pageNumberView]; // Add page numbers display view
		
		// create the track control view
		self.trackControl = [[ReaderTrackControl alloc] initWithFrame:self.bounds];
		[trackControl addTarget:self action:@selector(trackViewTouchDown:) forControlEvents:UIControlEventTouchDown];
		[trackControl addTarget:self action:@selector(trackViewValueChanged:) forControlEvents:UIControlEventValueChanged];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpInside];

		[self addSubview:trackControl]; // Add the track control and thumbs view

		self.document = object;
		[self updatePageNumberText:[document.pageNumber integerValue]];

		self.miniThumbViews = [NSMutableDictionary new]; // Small thumbs
	}

	return self;
}

- (void)removeFromSuperview
{
	[trackTimer invalidate];
	self.trackTimer = nil;
	[enableTimer invalidate];
	self.enableTimer = nil;
	
	[super removeFromSuperview];
}

- (void)layoutSubviews
{
	CGRect controlRect = CGRectInset(self.bounds, 4.0f, 0.0f);
	CGFloat thumbWidth = (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP);
	NSInteger thumbs = (controlRect.size.width / thumbWidth);
	NSInteger pages = [document epPageCount];
	if (thumbs > pages) {
		thumbs = pages;
	}
	
	CGFloat controlWidth = ((thumbs * thumbWidth) - THUMB_SMALL_GAP);
	controlRect.size.width = controlWidth;
	CGFloat widthDelta = (self.bounds.size.width - controlWidth);
	NSInteger X = (widthDelta / 2.0f); controlRect.origin.x = X;
	trackControl.frame = controlRect;
	
	// create the page thumb view when needed
	if (pageThumbView == nil) {
		CGFloat heightDelta = (controlRect.size.height - THUMB_LARGE_HEIGHT);
		NSInteger thumbY = (heightDelta / 2.0f);
		NSInteger thumbX = 0;
		CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT);
		
		self.pageThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect];
		pageThumbView.layer.zPosition = 1.0f;					// Z position so that it sits on top of the small thumbs
		[trackControl addSubview:pageThumbView];				// Add as the first subview of the track control
	}

	[self updatePageThumbView:[document.pageNumber integerValue]]; // Update page thumb view

	NSInteger strideThumbs = (thumbs - 1); if (strideThumbs < 1) strideThumbs = 1;
	CGFloat stride = ((CGFloat)pages / (CGFloat)strideThumbs); // Page stride
	CGFloat heightDelta = (controlRect.size.height - THUMB_SMALL_HEIGHT);
	NSInteger thumbY = (heightDelta / 2.0f); NSInteger thumbX = 0; // Initial X, Y
	
	CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);
	
	NSMutableDictionary *thumbsToHide = [miniThumbViews mutableCopy];
	for (NSInteger thumb = 0; thumb < thumbs; thumb++) // Iterate through needed thumbs
	{
		NSInteger page = ((stride * thumb) + 1); if (page > pages) page = pages; // Page
		NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key for thumb view
		
		ReaderPagebarThumb *smallThumbView = [miniThumbViews objectForKey:key]; // Thumb view
		if (smallThumbView == nil) // We need to create a new small thumb view for the page number
		{
			CGSize size = CGSizeMake(THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT); // Maximum thumb size
			NSURL *fileURL = document.fileURL;
			NSString *guid = document.guid;
			NSString *phrase = document.password;
			
			smallThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect small:YES]; // Create a small thumb view
			ReaderThumbRequest *thumbRequest = [ReaderThumbRequest forView:smallThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];
			[thumbRequest processWithoutPriority];

			[trackControl addSubview:smallThumbView];
			[miniThumbViews setObject:smallThumbView forKey:key];
			smallThumbView = nil; // Cleanup
		}
		else // Resue existing small thumb view for the page number
		{
			smallThumbView.hidden = NO;
			[thumbsToHide removeObjectForKey:key];
			
			if (CGRectEqualToRect(smallThumbView.frame, thumbRect) == false)
			{
				smallThumbView.frame = thumbRect; // Update thumb frame
			}
		}

		thumbRect.origin.x += thumbWidth; // Next thumb X position
	}
	
	[thumbsToHide enumerateKeysAndObjectsUsingBlock: // Hide unused thumbs
		^(id key, id object, BOOL *stop)
		{
			ReaderPagebarThumb *thumb = object; thumb.hidden = YES;
		}
	];
}

- (void)updatePagebarViews
{
	NSInteger page = [document.pageNumber integerValue]; // #
	[self updatePageNumberText:page]; // Update page number text
	[self updatePageThumbView:page]; // Update page thumb view
}

- (void)updatePagebar
{
	if (self.hidden == NO) {
		[self updatePagebarViews];
	}
}

- (void)hidePagebar
{
	if (self.hidden == NO) {
		self.alpha = 0.0f;
		self.hidden = YES;
	}
}

- (void)showPagebar
{
	if (self.hidden == YES) {
		[self updatePagebarViews]; // Update views first
		self.hidden = NO;
		self.alpha = 1.0f;
	}
}

#pragma mark ReaderTrackControl action methods

- (void)trackTimerFired:(NSTimer *)timer
{
	[trackTimer invalidate];
	self.trackTimer = nil; // Cleanup
	
	if (trackControl.tag != [document.pageNumber integerValue]) {
		[delegate pagebar:self gotoPage:trackControl.tag]; // Go to document page
	}
}

- (void)enableTimerFired:(NSTimer *)timer
{
	[enableTimer invalidate];
	self.enableTimer = nil;
	
	trackControl.userInteractionEnabled = YES;
}

- (void)restartTrackTimer
{
	if (trackTimer != nil) {
		[trackTimer invalidate];
	}
	
	self.trackTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(trackTimerFired:) userInfo:nil repeats:NO];
}

- (void)startEnableTimer
{
	if (enableTimer) {
		[enableTimer invalidate];
	}
	
	self.enableTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(enableTimerFired:) userInfo:nil repeats:NO];
}

- (NSInteger)trackViewPageNumber:(ReaderTrackControl *)trackView
{
	CGFloat controlWidth = trackView.bounds.size.width;
	CGFloat stride = (controlWidth / [document epPageCount]);
	NSInteger page = (trackView.value / stride);				// Integer page number
	
	return (page + 1); // + 1
}

- (void)trackViewTouchDown:(ReaderTrackControl *)trackView
{
	NSInteger page = [self trackViewPageNumber:trackView];
	if (page != [document.pageNumber integerValue]) {
		[self updatePageNumberText:page];
		[self updatePageThumbView:page];
		[self restartTrackTimer];
	}
	
	trackView.tag = page; // Start page tracking
}

- (void)trackViewValueChanged:(ReaderTrackControl *)trackView
{
	NSInteger page = [self trackViewPageNumber:trackView];
	
	if (page != trackView.tag) {			// Only if the page number has changed
		[self updatePageNumberText:page];
		[self updatePageThumbView:page];
		
		trackView.tag = page;
		[self restartTrackTimer];
	}
}

- (void)trackViewTouchUp:(ReaderTrackControl *)trackView
{
	[trackTimer invalidate];
	self.trackTimer = nil;
	
	if (trackView.tag != [document.pageNumber integerValue]) {
		trackView.userInteractionEnabled = NO;
		[delegate pagebar:self gotoPage:trackView.tag];
		[self startEnableTimer];			// Start track control enable timer
	}

	trackView.tag = 0;
}

@end

#pragma mark -

//
//	ReaderTrackControl class implementation
//

@implementation ReaderTrackControl

#pragma mark Properties

@synthesize value = _value;

#pragma mark ReaderTrackControl instance methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingNone;
		self.backgroundColor = [UIColor clearColor];
	}
	
	return self;
}


- (CGFloat)limitValue:(CGFloat)valueX
{
	CGFloat minX = self.bounds.origin.x; // 0.0f;
	CGFloat maxX = (self.bounds.size.width - 1.0f);
	
	if (valueX < minX) valueX = minX; // Minimum X
	if (valueX > maxX) valueX = maxX; // Maximum X
	
	return valueX;
}

#pragma mark UIControl subclass methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self];
	_value = [self limitValue:point.x];
	
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (self.touchInside == YES) {
		CGPoint point = [touch locationInView:touch.view];
		CGFloat x = [self limitValue:point.x];				// Potential new control value
		if (x != _value) {									// Only if the new value has changed since the last time
			_value = x; [self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}
	
	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint point = [touch locationInView:self];
	_value = [self limitValue:point.x];						// Limit control value
}

@end

#pragma mark -

//
//	ReaderPagebarThumb class implementation
//

@implementation ReaderPagebarThumb

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarThumb instance methods

- (id)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame small:NO];
}

- (id)initWithFrame:(CGRect)frame small:(BOOL)small
{
	if ((self = [super initWithFrame:frame])) {
		CGFloat value = (small ? 0.6f : 0.7f); // Size based alpha value
		UIColor *background = [UIColor colorWithWhite:0.8f alpha:value];
		
		self.backgroundColor = background;
		imageView.backgroundColor = background;
		imageView.layer.borderColor = [UIColor colorWithWhite:0.4f alpha:0.6f].CGColor;
		imageView.layer.borderWidth = 1.0f; // Give the thumb image view a border
	}

	return self;
}


@end

#pragma mark -

//
//	ReaderPagebarShadow class implementation
//

@implementation ReaderPagebarShadow

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarShadow class methods

+ (Class)layerClass
{
	DXLog(@"");

	return [CAGradientLayer class];
}

#pragma mark ReaderPagebarShadow instance methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *blackColor = [UIColor colorWithWhite:0.42f alpha:1.0f];
		UIColor *clearColor = [UIColor colorWithWhite:0.42f alpha:0.0f];
		layer.colors = [NSArray arrayWithObjects:(id)clearColor.CGColor, (id)blackColor.CGColor, nil];
	}

	return self;
}


@end
