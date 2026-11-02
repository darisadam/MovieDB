//
//  MDBCarouselCell.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

/// Full width backdrop for the Now Playing carousel on Home.
@interface MDBCarouselCell : UICollectionViewCell

@property (class, nonatomic, readonly) NSString *identifier;

- (void)configureWithModel:(MDBMovieCellModel *)model pageIndex:(NSInteger)pageIndex pageCount:(NSInteger)pageCount;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
