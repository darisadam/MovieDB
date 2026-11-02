//
//  MDBMovieListCell.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

/// Poster thumbnail with title, meta, rating and two lines of overview.
/// Used for search results and favorites.
@interface MDBMovieListCell : UITableViewCell

@property (class, nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy, nullable) void (^onFavoriteTapped)(void);

- (void)configureWithModel:(MDBMovieCellModel *)model showsFavorite:(BOOL)showsFavorite;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
