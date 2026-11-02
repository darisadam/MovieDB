//
//  MDBRatingPillView.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Small dark pill with a yellow star and the score. Hides itself when there is no rating.
@interface MDBRatingPillView : UIView

- (void)setRatingText:(nullable NSString *)ratingText;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
