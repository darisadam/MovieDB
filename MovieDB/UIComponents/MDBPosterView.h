//
//  MDBPosterView.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Rounded poster image with an optional rating pill in the corner.
@interface MDBPosterView : UIView

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic) BOOL showsRating;

- (void)setImageURL:(nullable NSURL *)imageURL;
- (void)setRatingText:(nullable NSString *)ratingText;
/// Cancels the download and clears the image. Call from prepareForReuse.
- (void)reset;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
