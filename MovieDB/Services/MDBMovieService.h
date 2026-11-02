//
//  MDBMovieService.h
//  MovieDB
//
//  Small role protocols for talking to TMDB. A view model asks only for the roles it uses,
//  for example id<MDBMovieListProviding, MDBGenreProviding>, and tests stub just those.
//

#import <Foundation/Foundation.h>
#import "MDBAPIClient.h"

@class MDBGenre;
@class MDBMovie;
@class MDBMovieDetail;
@class MDBObservable<ObjectType>;
@class MDBPage<ObjectType>;
@class MDBPerson;

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

@protocol MDBMovieListProviding <NSObject>
- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind page:(NSInteger)page completion:(MDBMoviePageCompletion)completion;
- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion;
@end

@protocol MDBMovieSearching <NSObject>
- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)query page:(NSInteger)page completion:(MDBMoviePageCompletion)completion;
@end

@protocol MDBMovieDetailProviding <NSObject>
- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion;
@end

@protocol MDBPersonProviding <NSObject>
- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion;
@end

@protocol MDBGenreProviding <NSObject>
/// Genre id to name, starts empty and updates after fetchGenres succeeds.
@property (nonatomic, readonly) MDBObservable<NSDictionary<NSNumber *, NSString *> *> *genreNames;
- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion;
@end

/// Everything at once, used by the composition root.
@protocol
    MDBMovieService <MDBMovieListProviding, MDBMovieSearching, MDBMovieDetailProviding, MDBPersonProviding, MDBGenreProviding>
@end

/// Names for the given ids, skipping ones we don't know yet.
FOUNDATION_EXPORT NSArray<NSString *> *MDBGenreNamesForIDs(NSDictionary<NSNumber *, NSString *> *_Nullable names,
                                                           NSArray<NSNumber *> *genreIDs);

NS_ASSUME_NONNULL_END
