//
//  MDBMovieService.h
//  MovieDB
//
//  Everything the screens need from TMDB. View models only see this protocol,
//  tests pass in a stub.
//

#import <Foundation/Foundation.h>
#import "MDBAPIClient.h"

@class MDBMovie;
@class MDBMovieDetail;
@class MDBGenre;
@class MDBPerson;
@class MDBPage<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBMovieListKind) {
    MDBMovieListKindNowPlaying = 0,
    MDBMovieListKindPopular,
    MDBMovieListKindTopRated,
    MDBMovieListKindUpcoming,
    MDBMovieListKindTrending,
};

typedef NS_ENUM(NSInteger, MDBDiscoverSort) {
    MDBDiscoverSortPopularity = 0,
    MDBDiscoverSortRating,
    MDBDiscoverSortNewest,
};

FOUNDATION_EXPORT NSString *MDBMovieListKindTitle(MDBMovieListKind kind);
FOUNDATION_EXPORT NSString *MDBDiscoverSortTitle(MDBDiscoverSort sort);

typedef void (^MDBMoviePageCompletion)(MDBPage<MDBMovie *> *_Nullable page, NSError *_Nullable error);
typedef void (^MDBGenreListCompletion)(NSArray<MDBGenre *> *_Nullable genres, NSError *_Nullable error);
typedef void (^MDBMovieDetailCompletion)(MDBMovieDetail *_Nullable detail, NSError *_Nullable error);
typedef void (^MDBPersonCompletion)(MDBPerson *_Nullable person, NSError *_Nullable error);

@protocol MDBMovieService <NSObject>

- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind
                                page:(NSInteger)page
                          completion:(MDBMoviePageCompletion)completion;

- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)query
                                       page:(NSInteger)page
                                 completion:(MDBMoviePageCompletion)completion;

- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion;

- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion;

- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion;

- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion;

/// Names for the genre ids we already know. Empty until fetchGenres has finished once.
- (NSArray<NSString *> *)genreNamesForIDs:(NSArray<NSNumber *> *)genreIDs;

@end

NS_ASSUME_NONNULL_END
