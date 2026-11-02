//
//  MDBExploreViewModel.m
//  MovieDB
//

#import "MDBExploreViewModel.h"
#import "MDBAPIError.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBPage.h"
#import "MDBPreferences.h"

static const NSUInteger MDBGenreShortcutLimit = 10;

@interface MDBExploreViewModel ()
@property (nonatomic, readwrite) MDBExploreMode mode;
@property (nonatomic, readwrite) MDBLoadState browseState;
@property (nonatomic, readwrite, nullable) NSError *browseError;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *trendingItems;
@property (nonatomic, copy, readwrite) NSArray<MDBGenre *> *genreShortcuts;
@property (nonatomic, copy, readwrite) NSString *query;
@property (nonatomic, readwrite) MDBLoadState searchState;
@property (nonatomic, readwrite, nullable) NSError *searchError;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *results;
@property (nonatomic, readwrite) NSInteger totalResults;
@property (nonatomic, readwrite, getter=isLoadingMore) BOOL loadingMore;

@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, readonly) NSTimeInterval debounceInterval;
@property (nonatomic, copy) NSArray<MDBMovie *> *trendingMovies;
@property (nonatomic, nullable) id<MDBCancellable> trendingTask;
@property (nonatomic, nullable) id<MDBCancellable> genresTask;
@property (nonatomic, nullable) id<MDBCancellable> searchTask;
@property (nonatomic) NSUInteger searchGeneration;
@property (nonatomic) NSInteger resultsPage;
@property (nonatomic) NSInteger resultsTotalPages;
@property (nonatomic) id preferencesObserver;
@end

@implementation MDBExploreViewModel

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                           imageURLs:(MDBImageURLBuilder *)imageURLs
                  notificationCenter:(NSNotificationCenter *)notificationCenter
                    debounceInterval:(NSTimeInterval)debounceInterval {
    self = [super init];
    if (self) {
        _movieService = movieService;
        _imageURLs = imageURLs;
        _notificationCenter = notificationCenter;
        _debounceInterval = MAX(0, debounceInterval);
        _trendingItems = @[];
        _trendingMovies = @[];
        _genreShortcuts = @[];
        _results = @[];
        _query = @"";

        __weak typeof(self) weakSelf = self;
        _preferencesObserver = [notificationCenter addObserverForName:MDBPreferencesDidChangeNotification
                                                               object:nil
                                                                queue:[NSOperationQueue mainQueue]
                                                           usingBlock:^(NSNotification *note) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf reloadBrowse];
            if (strongSelf.mode == MDBExploreModeSearch) {
                [strongSelf retrySearch];
            }
        }];
    }
    return self;
}

- (void)dealloc {
    [_trendingTask cancel];
    [_genresTask cancel];
    [_searchTask cancel];
    if (_preferencesObserver) {
        [_notificationCenter removeObserver:_preferencesObserver];
    }
}

#pragma mark - Browse

- (void)loadIfNeeded {
    if (self.browseState == MDBLoadStateIdle || self.browseState == MDBLoadStateFailed) {
        [self reloadBrowse];
    }
}

- (void)reloadBrowse {
    MDBAssertMainThread();
    [self.trendingTask cancel];
    [self.genresTask cancel];
    self.browseState = MDBLoadStateLoading;
    self.browseError = nil;
    [self notifyChange];

    __weak typeof(self) weakSelf = self;
    self.genresTask = [self.movieService fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || genres.count == 0) {
            return;
        }
        strongSelf.genreShortcuts = [genres subarrayWithRange:NSMakeRange(0, MIN(genres.count, MDBGenreShortcutLimit))];
        // Now that genre names are known, the result subtitles can show them.
        strongSelf.trendingItems = [strongSelf cellModelsForMovies:strongSelf.trendingMovies];
        [strongSelf notifyChange];
    }];

    self.trendingTask = [self.movieService fetchMovieList:MDBMovieListKindTrending page:1 completion:^(MDBPage<MDBMovie *> *page, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || error.mdb_isCancelled) {
            return;
        }
        if (page) {
            strongSelf.trendingMovies = page.results;
            strongSelf.trendingItems = [strongSelf cellModelsForMovies:page.results];
            strongSelf.browseState = page.results.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
        } else {
            strongSelf.browseState = MDBLoadStateFailed;
            strongSelf.browseError = error;
        }
        [strongSelf notifyChange];
    }];
}

#pragma mark - Search

- (void)updateQuery:(NSString *)query {
    MDBAssertMainThread();
    NSString *trimmed = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed isEqualToString:self.query] && self.mode == MDBExploreModeSearch) {
        return;
    }
    self.query = trimmed;
    self.searchGeneration += 1;
    [self.searchTask cancel];
    self.searchTask = nil;

    if (trimmed.length == 0) {
        self.mode = MDBExploreModeBrowse;
        self.searchState = MDBLoadStateIdle;
        self.results = @[];
        self.totalResults = 0;
        [self notifyChange];
        return;
    }

    self.mode = MDBExploreModeSearch;
    self.searchState = MDBLoadStateLoading;
    self.searchError = nil;
    [self notifyChange];

    NSUInteger generation = self.searchGeneration;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.debounceInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // A newer keystroke already replaced this query.
        if (!strongSelf || strongSelf.searchGeneration != generation) {
            return;
        }
        [strongSelf performSearchPage:1 generation:generation];
    });
}

- (void)submitQuery {
    if (self.query.length == 0) {
        return;
    }
    self.searchGeneration += 1;
    [self.searchTask cancel];
    self.searchState = MDBLoadStateLoading;
    [self notifyChange];
    [self performSearchPage:1 generation:self.searchGeneration];
}

- (void)retrySearch {
    [self submitQuery];
}

- (void)loadMoreResultsIfNeededForIndex:(NSInteger)index {
    if (self.mode != MDBExploreModeSearch || self.isLoadingMore || self.searchState != MDBLoadStateLoaded) {
        return;
    }
    if (self.resultsPage >= self.resultsTotalPages || index < (NSInteger)self.results.count - 5) {
        return;
    }
    self.loadingMore = YES;
    [self notifyChange];
    [self performSearchPage:self.resultsPage + 1 generation:self.searchGeneration];
}

- (void)performSearchPage:(NSInteger)page generation:(NSUInteger)generation {
    NSString *query = self.query;
    MDBLogDebug(MDBLogCategoryUI, @"Search \"%@\" page %ld", query, (long)page);
    __weak typeof(self) weakSelf = self;
    self.searchTask = [self.movieService searchMoviesWithQuery:query page:page completion:^(MDBPage<MDBMovie *> *result, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.searchGeneration != generation || error.mdb_isCancelled) {
            return;
        }
        strongSelf.loadingMore = NO;
        if (!result) {
            if (page == 1) {
                strongSelf.searchState = MDBLoadStateFailed;
                strongSelf.searchError = error;
            }
            [strongSelf notifyChange];
            return;
        }
        NSArray<MDBMovieCellModel *> *models = [strongSelf cellModelsForMovies:result.results];
        if (page == 1) {
            strongSelf.results = models;
        } else {
            NSMutableSet<NSNumber *> *existing = [NSMutableSet set];
            for (MDBMovieCellModel *model in strongSelf.results) {
                [existing addObject:@(model.movieID)];
            }
            NSMutableArray<MDBMovieCellModel *> *merged = [strongSelf.results mutableCopy];
            for (MDBMovieCellModel *model in models) {
                if (![existing containsObject:@(model.movieID)]) {
                    [merged addObject:model];
                }
            }
            strongSelf.results = merged;
        }
        strongSelf.resultsPage = result.page;
        strongSelf.resultsTotalPages = result.totalPages;
        strongSelf.totalResults = result.totalResults;
        strongSelf.searchState = strongSelf.results.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
        [strongSelf notifyChange];
    }];
}

- (NSString *)resultsSummary {
    NSString *noun = self.totalResults == 1 ? @"result" : @"results";
    return [NSString stringWithFormat:@"%ld %@ for ‘%@’", (long)self.totalResults, noun, self.query];
}

#pragma mark - Helpers

- (NSArray<MDBMovieCellModel *> *)cellModelsForMovies:(NSArray<MDBMovie *> *)movies {
    id<MDBMovieService> service = self.movieService;
    return [MDBMovieCellModel modelsWithMovies:movies
                            genreNamesProvider:^NSArray<NSString *> *(NSArray<NSNumber *> *genreIDs) {
        return [service genreNamesForIDs:genreIDs];
    }
                                     imageURLs:self.imageURLs];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
