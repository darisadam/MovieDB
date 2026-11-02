//
//  MDBMovieCellModel.h
//  MovieDB
//
//  Display-ready values for any cell that shows a movie. View models build these,
//  cells only read them.
//

#import <Foundation/Foundation.h>

@class MDBMovie;
@class MDBFavoriteMovie;
@class MDBImageURLBuilder;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieCellModel : NSObject

@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *yearText;
/// "2015 · Action, Science Fiction"
@property (nonatomic, copy, readonly) NSString *metaText;
@property (nonatomic, copy, readonly) NSString *ratingText;
@property (nonatomic, readonly) double rating;
/// "(9.1k votes)"
@property (nonatomic, copy, readonly) NSString *votesText;
/// "Jun 16, 2017"
@property (nonatomic, copy, readonly) NSString *releaseDateText;
@property (nonatomic, copy, readonly) NSString *overview;
@property (nonatomic, copy, readonly, nullable) NSURL *posterURL;
@property (nonatomic, copy, readonly, nullable) NSURL *smallPosterURL;
@property (nonatomic, copy, readonly, nullable) NSURL *backdropURL;
/// Kept so favorites can be saved straight from a cell model.
@property (nonatomic, readonly, nullable) MDBMovie *movie;

+ (instancetype)modelWithMovie:(MDBMovie *)movie
                    genreNames:(NSArray<NSString *> *)genreNames
                     imageURLs:(MDBImageURLBuilder *)imageURLs;

+ (instancetype)modelWithFavorite:(MDBFavoriteMovie *)favorite imageURLs:(MDBImageURLBuilder *)imageURLs;

/// genreNames maps genre id to name, as published by MDBGenreProviding.
+ (NSArray<MDBMovieCellModel *> *)modelsWithMovies:(NSArray<MDBMovie *> *)movies
                                        genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames
                                         imageURLs:(MDBImageURLBuilder *)imageURLs;

- (instancetype)init NS_UNAVAILABLE;

/// "Green Book, 2018, rated 8.2" for VoiceOver.
- (NSString *)accessibilityLabelText;

@end

NS_ASSUME_NONNULL_END
