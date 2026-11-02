//
//  MDBMovieDetailViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBCastCellModel;
@class MDBImageURLBuilder;
@class MDBMovie;
@class MDBMovieCellModel;
@class MDBMovieDetail;
@class MDBVideo;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieFact : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *value;
- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface MDBMovieDetailViewModel : NSObject

@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, readonly) MDBLoadState state;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, readonly, nullable) MDBMovieDetail *detail;

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
@property (nonatomic, readonly) BOOL hasTrailer;
@property (nonatomic, readonly, getter=isFavorite) BOOL favorite;
@property (nonatomic, readonly, nullable) NSURL *shareURL;

@property (nonatomic, copy, nullable) void (^onChange)(void);

/// The seed movie lets the header show a title and image before the detail request finishes.
- (instancetype)initWithMovieID:(NSInteger)movieID
                       seedMovie:(nullable MDBMovie *)seedMovie
                    movieService:(id<MDBMovieService>)movieService
                  favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                       imageURLs:(MDBImageURLBuilder *)imageURLs
              notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)load;
- (void)toggleFavorite;

@end

NS_ASSUME_NONNULL_END
