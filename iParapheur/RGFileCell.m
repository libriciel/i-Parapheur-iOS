
#import "RGFileCell.h"
#import "UIColor+CustomColors.h"


NSString *const RGFileCellShouldHideMenuNotification = @"RGFileCellShouldHideMenuNotification";

@interface RGFileCell() {
    BOOL _isScrolling;
}
    
@property (strong, nonatomic) UIButton *checkBox;

@end


@implementation RGFileCell

@synthesize indexPath = _indexPath;
@synthesize tableView = _tableView;


-(id)initWithStyle:(UITableViewCellStyle)style
   reuseIdentifier:(NSString *)reuseIdentifier {
	
	
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
        [self setup];
		
    return self;
}


-(void)awakeFromNib {
    [self setup];
}


-(void)setup {
    
    //[self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    // Create a scroll view to handle swipe to show actions
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + kCatchWidth, CGRectGetHeight(self.bounds));
    self.scrollView.delegate = self;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidSelectCell:)];
    [self.scrollView addGestureRecognizer:singleTap];
    
    [self.contentView addSubview:self.scrollView];
    
    // create and add the view containing the actions buttons
    self.buttonsView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - kCatchWidth, 0, kCatchWidth, CGRectGetHeight(self.bounds))];
    [self.scrollView addSubview:self.buttonsView];
    
    // Create and add thes actions buttons
    // MORE
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.moreButton.backgroundColor = [UIColor grayColor];
    self.moreButton.frame = CGRectMake(0, 0, kCatchWidth / 2.0f, CGRectGetHeight(self.bounds));
    [self.moreButton setTitle:@"Plus" forState:UIControlStateNormal];
    [self.moreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(userPressedMoreButton) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonsView addSubview:self.moreButton];
	
    // VALIDATE
    self.validateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.validateButton.backgroundColor = [UIColor darkGreenColor];
    self.validateButton.frame = CGRectMake(kCatchWidth / 2.0f, 0, kCatchWidth / 2.0f, CGRectGetHeight(self.bounds));
    [self.validateButton setTitle:@"Valider" forState:UIControlStateNormal];
    [self.validateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.validateButton.titleLabel.lineBreakMode = (NSLineBreakByWordWrapping);
    self.validateButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.validateButton addTarget:self action:@selector(userPressedValidateButton) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonsView addSubview:self.validateButton];
    
    // Create and add the "normal" list item
    self.contentCellView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    self.contentCellView.backgroundColor = [UIColor whiteColor];
    [self.scrollView addSubview:self.contentCellView];
    //Titre du dossier
    self.dossierTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0f, 0.0f, CGRectGetWidth(self.bounds) - 75.0f, CGRectGetHeight(self.bounds)*0.4f)];
    [self.dossierTitleLabel setLineBreakMode:NSLineBreakByWordWrapping | NSLineBreakByTruncatingTail];
    //self.dossierTitleLabel.textAlignment = NSTextAlignmentRight;
    [self.contentCellView addSubview:self.dossierTitleLabel];
    //Typologie
    self.typologyLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0f, CGRectGetHeight(self.bounds)*0.4f, CGRectGetWidth(self.bounds) - 75.0f, CGRectGetHeight(self.bounds)*0.4f)];
    self.typologyLabel.lineBreakMode = (NSLineBreakByWordWrapping | NSLineBreakByTruncatingTail);
    self.typologyLabel.font = [UIFont systemFontOfSize:14];
	self.typologyLabel.textColor = [UIColor grayColor];
    //self.typologyLabel.textAlignment = NSTextAlignmentRight;
    [self.contentCellView addSubview:self.typologyLabel];
    
    // SWITCH
    self.switchButton = [[UISwitch alloc] initWithFrame:CGRectMake(5.0f, 20.0f, 20.0f, 20.0f)];
    self.switchButton.on = NO;
    [self.switchButton addTarget:self action:@selector(userDidCheckCell:) forControlEvents:(UIControlEventValueChanged | UIControlEventTouchDragInside)];
    [self.contentCellView addSubview:self.switchButton];
    
    // RETARD
    self.retardPlaceHolder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetHeight(self.bounds) - 25.0f, 20.0f, 20.0f)];
    self.retardBadge = [CustomBadge customBadgeWithString:@""];
	[self.retardBadge.badgeStyle setBadgeInsetColor:[UIColor darkRedColor]];
    [self.retardBadge setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [self.retardPlaceHolder addSubview:self.retardBadge];
    [self.contentCellView addSubview:self.retardPlaceHolder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMenuOptions) name:RGFileCellShouldHideMenuNotification object:nil];
}

-(void) removeFromSuperview {
	
	[_moreButton removeTarget:nil
					   action:NULL
			 forControlEvents:UIControlEventAllEvents];
	
	[_validateButton removeTarget:nil
						   action:NULL
				 forControlEvents:UIControlEventAllEvents];
	
	[_switchButton removeTarget:nil
						 action:NULL
			   forControlEvents:UIControlEventAllEvents];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super removeFromSuperview];
}


-(BOOL)isChecked {
    return [self.checkBox isSelected];
}


-(void)flickerSelection {
	_contentCellView.backgroundColor = [UIColor selectedCellGreyColor];

	[UIView animateWithDuration:0.4 animations:^{
		_contentCellView.backgroundColor = [UIColor whiteColor];
	}];
}


-(void)userDidSelectCell:(UITapGestureRecognizer *)gesture {
	
    if ([self.delegate respondsToSelector:@selector(willSelectCell:)])
        [self.delegate willSelectCell:self];
	
    if ([self.delegate respondsToSelector:@selector(cell:didSelectAtIndexPath:)])
        [self.delegate cell:self didSelectAtIndexPath:self.indexPath];
}


-(void)userDidCheckCell:(UITapGestureRecognizer *)gesture {
	
    if ([self.delegate respondsToSelector:@selector(cell:didCheckAtIndexPath:)])
        [self.delegate cell:self didCheckAtIndexPath:self.indexPath];
}


-(void)userPressedValidateButton {
	
    if ([self.delegate respondsToSelector:@selector(cell:didTouchMainButtonAtIndexPath:)])
        [self.delegate cell:self didTouchMainButtonAtIndexPath:self.indexPath];
}


-(void)userPressedMoreButton {
	
    if ([self.delegate respondsToSelector:@selector(cell:didTouchSecondaryButtonAtIndexPath:)])
        [self.delegate cell:self didTouchSecondaryButtonAtIndexPath:self.indexPath];
}


-(UITableView*)tableView {
    if (!_tableView) {
        // get the parent tableView
        id view = [self superview];
		
        while ([view isKindOfClass:[UITableView class]] == NO)
            view = [view superview];
		
        _tableView = view;
    }
    return _tableView;
}


-(NSIndexPath*)indexPath {
    if (!_indexPath) {
        _indexPath = [self.tableView indexPathForCell: self];
    }
    return _indexPath;
}


-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) + kCatchWidth, CGRectGetHeight(self.bounds));
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    self.buttonsView.frame = CGRectMake(CGRectGetWidth(self.bounds) - kCatchWidth, 0, kCatchWidth, CGRectGetHeight(self.bounds));
    self.buttonsView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}


-(void)prepareForReuse {
    [super prepareForReuse];
    [self.scrollView setContentOffset:CGPointZero animated:NO];
}


-(UILabel *)textLabel {
    // Kind of a cheat to reduce our external dependencies
    return self.dossierTitleLabel;
}


-(void)hideMenuOptions {
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


#pragma mark - UIScrollViewDelegate protocol implementation


-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(canSwipeCell:)] && [self.delegate canSwipeCell:self]) {
        _isScrolling = YES;
		
        if (scrollView.contentOffset.x < 0)
            scrollView.contentOffset = CGPointZero;
        
        self.buttonsView.frame = CGRectMake(scrollView.contentOffset.x + (CGRectGetWidth(self.bounds) - kCatchWidth), 0.0f, kCatchWidth, CGRectGetHeight(self.bounds));
    }
    else {
        if (!_isScrolling)
            scrollView.contentOffset = CGPointZero;
    }
}


-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	
    if ([self.delegate respondsToSelector:@selector(willSwipeCell:)])
        [self.delegate willSwipeCell:self];
}


-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView
					withVelocity:(CGPoint)velocity
			 targetContentOffset:(inout CGPoint *)targetContentOffset {
	
    if (scrollView.contentOffset.x > kCatchWidth) {
        targetContentOffset->x = kCatchWidth;
    }
    else {
        *targetContentOffset = CGPointZero;
        
        // Need to call this subsequently to remove flickering.
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView setContentOffset:CGPointZero animated:YES];
        });
    }
}


-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    _isScrolling = NO;
}


-(void)setSelected:(BOOL)selected
		  animated:(BOOL)animated {
	
    if (selected) {
        if (![self.delegate respondsToSelector:@selector(canSelectCell:)] || [self.delegate canSelectCell:self]) {
            _contentCellView.backgroundColor = [UIColor selectedCellGreyColor];
        }
    }
    else {
			_contentCellView.backgroundColor = [UIColor whiteColor];
    }
}


@end


