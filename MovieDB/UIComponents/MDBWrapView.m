//
//  MDBWrapView.m
//  MovieDB
//

#import "MDBWrapView.h"

@interface MDBWrapView ()
@property (nonatomic, copy) NSArray<UIView *> *itemViews;
@property (nonatomic) CGFloat lastLayoutWidth;
@end

@implementation MDBWrapView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    _horizontalSpacing = 8;
    _verticalSpacing = 10;
    _itemViews = @[];
  }
  return self;
}

- (void)setItemViews:(NSArray<UIView *> *)itemViews {
  for (UIView *view in _itemViews) {
    [view removeFromSuperview];
  }
  _itemViews = [itemViews copy];
  for (UIView *view in _itemViews) {
    // Frames are set by hand in layoutSubviews.
    view.translatesAutoresizingMaskIntoConstraints = YES;
    [self addSubview:view];
  }
  [self invalidateIntrinsicContentSize];
  [self setNeedsLayout];
}

- (CGFloat)layoutItemsForWidth:(CGFloat)width apply:(BOOL)apply {
  if (width <= 0) {
    return 0;
  }
  CGFloat x = 0;
  CGFloat y = 0;
  CGFloat rowHeight = 0;
  for (UIView *view in self.itemViews) {
    CGSize size = [view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    size.width = MIN(size.width, width);
    if (x > 0 && x + size.width > width) {
      x = 0;
      y += rowHeight + self.verticalSpacing;
      rowHeight = 0;
    }
    if (apply) {
      view.frame = CGRectMake(x, y, size.width, size.height);
    }
    x += size.width + self.horizontalSpacing;
    rowHeight = MAX(rowHeight, size.height);
  }
  return y + rowHeight;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  CGFloat width = self.bounds.size.width;
  [self layoutItemsForWidth:width apply:YES];
  if (fabs(width - self.lastLayoutWidth) > 0.5) {
    self.lastLayoutWidth = width;
    [self invalidateIntrinsicContentSize];
  }
}

- (CGSize)intrinsicContentSize {
  // Before the first layout pass we don't know our width yet, so guess an iPhone content width.
  CGFloat width = self.lastLayoutWidth > 0 ? self.lastLayoutWidth : 335;
  return CGSizeMake(UIViewNoIntrinsicMetric, [self layoutItemsForWidth:width apply:NO]);
}

@end
