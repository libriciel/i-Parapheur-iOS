//
//  ADLInfoView.m
//  iParapheur
//
//  Created by Jason MAIRE on 25/01/2014.
//
//

#import "ADLInfoView.h"

@implementation ADLInfoView
@synthesize annotationModel = _annotationModel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor lightGrayColor];
        self.author = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height / 4)];
        
        self.date = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.height / 4, 0.0f, self.bounds.size.width, self.bounds.size.height / 4)];
        
        self.info = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.height / 2, 0.0f, self.bounds.size.width, self.bounds.size.height / 2)];
        
        [self addSubview:self.author];
        [self addSubview:self.date];
        [self addSubview:self.info];
    }
    return self;
}

-(void) setAnnotationModel:(ADLAnnotation *)annotationModel {
    _annotationModel = annotationModel;
    self.author.text = annotationModel.author;
    self.date.text = annotationModel.date;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
