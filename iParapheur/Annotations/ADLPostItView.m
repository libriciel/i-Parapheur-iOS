/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
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
#import "ADLPostItView.h"


@implementation ADLPostItView

@synthesize annotationModel = _annotationModel;


- (id)initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code
		/*
		_label = [[UILabel alloc] initWithFrame:[self bounds]];
		[_label setBackgroundColor:[UIColor yellowColor]];
		[_label setLineBreakMode:NSLineBreakByWordWrapping];
		[_label setNumberOfLines:4];
		*/
		_textView = [[UITextView alloc] initWithFrame:self.bounds];
		_textView.font = [UIFont systemFontOfSize:20];
		_textView.backgroundColor = [UIColor yellowColor];
		_textView.delegate = self;

		[self addSubview:_textView];
	}
	return self;
}


- (void)textViewDidEndEditing:(UITextView *)textView {

	_annotationModel.text = textView.text;
}


- (void)setAnnotationModel:(Annotation *)annotationModel {

	_annotationModel = annotationModel;
	_textView.text = annotationModel.text;

	CGSize size = [annotationModel.text boundingRectWithSize:CGSizeMake(100.0f, FLT_MAX)
	                                                 options:NSStringDrawingUsesLineFragmentOrigin
	                                              attributes:@{NSFontAttributeName : _textView.font}
	                                                 context:nil].size;

	size.width = 100.0f;
	size.height = size.height > 100.0f ? size.height : 100.0f;

	CGRect myFrame = self.frame;

	myFrame.size.width = size.width;
	myFrame.size.height = size.height;

	myFrame = CGRectInset(myFrame, -15, -15);
	[_textView setFrame: CGRectMake(15.0f, 15.0f, size.width, size.height)];
	[self setFrame:myFrame];
	
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
#if 0
- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(context);
	{
		[[UIColor yellowColor] setFill];
		CGContextFillRect(context, self.bounds);
		[[UIColor blackColor] setStroke];

	   /* CGContextSelectFont (context, // 3
							 "Helvetica-Bold",
							 12,
							 kCGEncodingMacRoman);*/
	   // CGContextScaleCTM(context, 1, -1);

		CGContextTranslateCTM(context, 0.0f, CGRectGetHeight(self.frame));
		CGContextScaleCTM(context, 1.0f, -1.0f);

		CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
		CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
		CGContextSelectFont(context, "Helvetica", 12, kCGEncodingMacRoman);
		CGContextSetTextDrawingMode(context, kCGTextFill);
		CGContextSetTextPosition(context, 0.0f, 0.0f);

		CGContextShowText(context, [[_annotationModel text] UTF8String], strlen([[_annotationModel text] UTF8String]));


		//CGContextSetCharacterSpacing (context, 10); // 4
		//CGContextSetTextDrawingMode (context, kCGTextFillStroke); // 5


		//CGContextShowTextAtPoint(context, 0, 0, "Quartz 2D", 12);

	}
	UIGraphicsPopContext();

}
#endif


- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {

	super.contentScaleFactor = contentScaleFactor;
	_label.contentScaleFactor = contentScaleFactor;
}


@end
