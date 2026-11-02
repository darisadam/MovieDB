//
//  UIView+MDBLayout.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (MDBLayout)

/// Pins all four edges to the given view with no inset.
- (void)mdb_pinToEdgesOfView:(UIView *)view;

/// Wraps the view in a container with the same inset on the left and right.
/// Lets a stack view mix edge to edge rows with padded content.
- (UIView *)mdb_wrappedWithHorizontalInset:(CGFloat)inset;

@end

NS_ASSUME_NONNULL_END
