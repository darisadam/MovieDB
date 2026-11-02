//
//  MDBExploreViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBMovieCellModel;
@class MDBImageURLBuilder;
@class MDBGenre;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBExploreMode) {
    MDBExploreModeBrowse = 0,  // trending grid and genre shortcuts
    MDBExploreModeSearch,      // search results for the current query
};

@interface MDBExploreViewModel : NSObject

@property (nonatomic, readonly) MDBExploreMode mode;

@property (nonatomic, readonly) MDBLoadState browseState;
@property (nonatomic, readonly, nullable) NSError *browseError;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *trendingItems;
@property (nonatomic, copy, readonly) NSArray<MDBGenre *> *genreShortcuts;

@property (nonatomic, copy, readonly) NSString *query;
@property (nonatomic, readonly) MDBLoadState searchState;
@property (nonatomic, readonly, nullable) NSError *searchError;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *results;
@property (nonatomic, readonly) NSInteger totalResults;
@property (nonatomic, readonly, getter=isLoadingMore) BOOL loadingMore;

@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                           imageURLs:(MDBImageURLBuilder *)imageURLs
                  notificationCenter:(NSNotificationCenter *)notificationCenter
                    debounceInterval:(NSTimeInterval)debounceInterval NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadIfNeeded;
- (void)reloadBrowse;

/// Debounced. An empty query goes back to browse mode right away.
- (void)updateQuery:(NSString *)query;
/// Skips the debounce, used when the user taps Search on the keyboard.
- (void)submitQuery;
- (void)retrySearch;
- (void)loadMoreResultsIfNeededForIndex:(NSInteger)index;

/// "3 results for ‘Maze Runner’"
- (NSString *)resultsSummary;

@end

NS_ASSUME_NONNULL_END
