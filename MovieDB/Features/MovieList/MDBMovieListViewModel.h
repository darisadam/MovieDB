//
//  MDBMovieListViewModel.h
//  MovieDB
//
//  Backs both "See All" (a TMDB list) and the genre screen (discover with a genre filter).
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBGenre;
@class MDBImageURLBuilder;
@class MDBObservable<ObjectType>;
@class MDBPagedItems;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

typedef id<MDBMovieListProviding, MDBGenreProviding> MDBMovieListServices;

@interface MDBMovieListViewModel : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, readonly) BOOL showsSortOptions;
@property (nonatomic, copy, readonly) NSArray<NSString *> *sortTitles;
/// NSNumber wrapping MDBDiscoverSort.
@property (nonatomic, readonly) MDBObservable<NSNumber *> *sort;
@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBPagedItems *> *> *state;

- (instancetype)initWithListKind:(MDBMovieListKind)kind
                        services:(MDBMovieListServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs;
- (instancetype)initWithGenre:(MDBGenre *)genre services:(MDBMovieListServices)services imageURLs:(MDBImageURLBuilder *)imageURLs;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadFirstPage;
- (void)loadMoreIfNeededForIndex:(NSInteger)index;
- (void)selectSortAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
