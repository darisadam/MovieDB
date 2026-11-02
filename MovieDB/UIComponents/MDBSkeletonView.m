//
//  MDBSkeletonView.m
//  MovieDB
//

#import "MDBSkeletonView.h"
#import "MDBTheme.h"

static NSString *const MDBShimmerAnimationKey = @"shimmer";

@interface MDBSkeletonView ()
@property (nonatomic, readonly) CAGradientLayer *gradient;
@end

@implementation MDBSkeletonView

+ (instancetype)blockWithCornerRadius:(CGFloat)cornerRadius {
  MDBSkeletonView *view = [[self alloc] initWithFrame:CGRectZero];
  view.layer.cornerRadius = cornerRadius;
  return view;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = UIColor.mdb_skeletonBase;
    self.clipsToBounds = YES;
    self.isAccessibilityElement = NO;

    _gradient = [CAGradientLayer layer];
    _gradient.colors = @[
      (id)UIColor.mdb_skeletonBase.CGColor,
      (id)UIColor.mdb_skeletonHighlight.CGColor,
      (id)UIColor.mdb_skeletonBase.CGColor,
    ];
    _gradient.locations = @[ @0.0, @0.5, @1.0 ];
    _gradient.startPoint = CGPointMake(0, 0.5);
    _gradient.endPoint = CGPointMake(1, 0.5);
    [self.layer addSublayer:_gradient];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  // Three times wider than the view so the highlight can slide across.
  self.gradient.frame = CGRectMake(-self.bounds.size.width, 0, self.bounds.size.width * 3, self.bounds.size.height);
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  [self updateAnimation];
}

- (void)updateAnimation {
  [self.gradient removeAnimationForKey:MDBShimmerAnimationKey];
  if (!self.window || UIAccessibilityIsReduceMotionEnabled()) {
    return;
  }
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"locations"];
  animation.fromValue = @[ @0.0, @0.15, @0.3 ];
  animation.toValue = @[ @0.7, @0.85, @1.0 ];
  animation.duration = 1.4;
  animation.repeatCount = HUGE_VALF;
  [self.gradient addAnimation:animation forKey:MDBShimmerAnimationKey];
}

@end
