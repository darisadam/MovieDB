//
//  UIView+MDBLayout.m
//  MovieDB
//

#import "UIView+MDBLayout.h"

@implementation UIView (MDBLayout)

- (void)mdb_pinToEdgesOfView:(UIView *)view {
  self.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
    [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
    [self.topAnchor constraintEqualToAnchor:view.topAnchor],
    [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
  ]];
}

- (UIView *)mdb_wrappedWithHorizontalInset:(CGFloat)inset {
  UIView *container = [[UIView alloc] init];
  self.translatesAutoresizingMaskIntoConstraints = NO;
  [container addSubview:self];
  [NSLayoutConstraint activateConstraints:@[
    [self.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:inset],
    [self.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-inset],
    [self.topAnchor constraintEqualToAnchor:container.topAnchor],
    [self.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
  ]];
  return container;
}

@end
