//
//  MDBExploreViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBGenre;
@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBObservable<ObjectType>;
@class MDBPagedItems;
@class MDBPreferenceSnapshot;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBExploreMode) {
  MDBExploreModeBrowse = 0,  // trending grid and genre shortcuts
  MDBExploreModeSearch,      // search results for the current query
};

@interface MDBExploreBrowseContent : NSObject
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *trendingItems;
@property (nonatomic, copy, readonly) NSArray<MDBGenre *> *genreShortcuts;
- (instancetype)initWithTrendingItems:(NSArray<MDBMovieCellModel *> *)trendingItems
                       genreShortcuts:(NSArray<MDBGenre *> *)genreShortcuts NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

typedef id<MDBMovieListProviding, MDBMovieSearching, MDBGenreProviding> MDBExploreServices;

@interface MDBExploreViewModel : NSObject

/// NSNumber wrapping MDBExploreMode.
@property (nonatomic, readonly) MDBObservable<NSNumber *> *mode;
@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBExploreBrowseContent *> *> *browseState;
@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBPagedItems *> *> *searchState;
/// The trimmed query, published right away (not debounced).
@property (nonatomic, readonly) MDBObservable<NSString *> *query;

- (instancetype)initWithServices:(MDBExploreServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs
                     preferences:(MDBObservable<MDBPreferenceSnapshot *> *)preferences
                debounceInterval:(NSTimeInterval)debounceInterval NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadIfNeeded;
- (void)reloadBrowse;

/// Called on every keystroke. Searching waits for the debounce, an empty query switches back to browse at once.
- (void)updateQuery:(NSString *)query;
/// Skips the debounce, used when the user taps Search on the keyboard.
- (void)submitQuery;
- (void)retrySearch;
- (void)loadMoreResultsIfNeededForIndex:(NSInteger)index;

/// "3 results for ‘Maze Runner’"
- (NSString *)resultsSummaryForItems:(MDBPagedItems *)items;

@end

NS_ASSUME_NONNULL_END
