//
//  MDBWrapView.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Lays out its subviews left to right and wraps to a new line, like chips in a tag cloud.
/// Works inside a stack view, the height follows the width it gets.
@interface MDBWrapView : UIView

@property (nonatomic) CGFloat horizontalSpacing;
@property (nonatomic) CGFloat verticalSpacing;

- (void)setItemViews:(NSArray<UIView *> *)itemViews;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
