//
//  MDBMovieListViewModel.h
//  MovieDB
//
//  Backs both "See All" (a TMDB list) and the genre screen (discover with a genre filter).
//

#import <Foundation/Foundation.h>
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBGenre;
@class MDBImageURLBuilder;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieListViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, readonly) BOOL showsSortOptions;
@property (nonatomic, readonly) MDBDiscoverSort sort;
@property (nonatomic, copy, readonly) NSArray<NSString *> *sortTitles;

@property (nonatomic, readonly) MDBLoadState state;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic, readonly) NSInteger totalResults;
@property (nonatomic, readonly, getter=isLoadingMore) BOOL loadingMore;

@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithListKind:(MDBMovieListKind)kind
                    movieService:(id<MDBMovieService>)movieService
                       imageURLs:(MDBImageURLBuilder *)imageURLs;

- (instancetype)initWithGenre:(MDBGenre *)genre
                 movieService:(id<MDBMovieService>)movieService
                    imageURLs:(MDBImageURLBuilder *)imageURLs;

- (instancetype)init NS_UNAVAILABLE;

- (void)loadFirstPage;
- (void)loadMoreIfNeededForIndex:(NSInteger)index;
- (void)selectSortAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
