//
//  MDBMovieDetailViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBMovieService.h"

@class MDBCastCellModel;
@class MDBImageURLBuilder;
@class MDBMovie;
@class MDBMovieCellModel;
@class MDBMovieDetail;
@class MDBObservable<ObjectType>;
@class MDBScreenState<ContentType>;
@class MDBVideo;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieFact : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *value;
- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/// Everything the detail screen draws, already formatted.
@interface MDBMovieDetailContent : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSURL *backdropURL;
/// "2016 · 2h 9m"
@property (nonatomic, copy, readonly) NSString *metaText;
@property (nonatomic, copy, readonly, nullable) NSString *ratingText;
@property (nonatomic, copy, readonly, nullable) NSString *tagline;
@property (nonatomic, copy, readonly) NSString *overview;
@property (nonatomic, copy, readonly) NSArray<NSString *> *genreNames;
@property (nonatomic, copy, readonly) NSArray<MDBMovieFact *> *facts;
@property (nonatomic, copy, readonly) NSArray<MDBCastCellModel *> *cast;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *recommendations;
@property (nonatomic, copy, readonly) NSArray<MDBVideo *> *videos;
/// True once the full detail arrived. Until then only the seed movie is shown.
@property (nonatomic, readonly, getter=isComplete) BOOL complete;
@property (nonatomic, readonly) BOOL hasTrailer;
@end

typedef id<MDBMovieDetailProviding, MDBGenreProviding> MDBMovieDetailServices;

@interface MDBMovieDetailViewModel : NSObject

@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBMovieDetailContent *> *> *state;
/// NSNumber BOOL, follows the favorites store.
@property (nonatomic, readonly) MDBObservable<NSNumber *> *isFavorite;
@property (nonatomic, readonly, nullable) NSURL *shareURL;

/// The seed movie lets the header show a title and image before the detail request finishes.
- (instancetype)initWithMovieID:(NSInteger)movieID
                      seedMovie:(nullable MDBMovie *)seedMovie
                       services:(MDBMovieDetailServices)services
                 favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                      imageURLs:(MDBImageURLBuilder *)imageURLs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)load;
- (void)toggleFavorite;

@end

NS_ASSUME_NONNULL_END
