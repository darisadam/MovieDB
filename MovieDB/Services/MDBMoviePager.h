//
//  MDBMoviePager.h
//  MovieDB
//
//  Infinite scroll for any paged TMDB list: search results, See All and genre results.
//  It keeps the page count, drops duplicates and ignores answers from a request that
//  was replaced in the meantime.
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBObservable<ObjectType>;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBPagedMovies : NSObject

@property (nonatomic, copy, readonly) NSArray<MDBMovie *> *movies;
@property (nonatomic, readonly) NSInteger totalResults;
@property (nonatomic, readonly, getter=isLoadingMore) BOOL loadingMore;

- (instancetype)initWithMovies:(NSArray<MDBMovie *> *)movies
                  totalResults:(NSInteger)totalResults
                   loadingMore:(BOOL)loadingMore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

/// Asks for one page. The pager calls it with 1, 2, 3 and so on.
typedef id<MDBCancellable> _Nonnull (^MDBMoviePageRequest)(NSInteger page, MDBMoviePageCompletion completion);

@interface MDBMoviePager : NSObject

@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBPagedMovies *> *> *state;

/// Start the next page when the user is this many items from the end.
- (instancetype)initWithPrefetchDistance:(NSInteger)prefetchDistance NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

/// Cancels whatever was running and loads page 1 with the new request.
- (void)startWithRequest:(MDBMoviePageRequest)request;
/// Shows loading right away, before the request starts. Used while a search is debouncing.
- (void)showLoading;
- (void)loadMoreIfNeededForIndex:(NSInteger)index;
/// Cancels and goes back to idle.
- (void)reset;

@end

NS_ASSUME_NONNULL_END
