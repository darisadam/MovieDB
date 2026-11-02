//
//  MDBSkeletonView.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Grey placeholder block with a soft shimmer. The shimmer stops when Reduce Motion is on
/// and while the view is off screen.
@interface MDBSkeletonView : UIView

+ (instancetype)blockWithCornerRadius:(CGFloat)cornerRadius;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
