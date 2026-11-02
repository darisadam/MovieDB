//
//  MDBExploreViewModel.m
//  MovieDB
//

#import "MDBExploreViewModel.h"
#import "MDBAPIError.h"
#import "MDBGenre.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBMoviePager.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBPagedItems.h"
#import "MDBScreenState.h"

static const NSUInteger MDBGenreShortcutLimit = 10;

@implementation MDBExploreBrowseContent

- (instancetype)initWithTrendingItems:(NSArray<MDBMovieCellModel *> *)trendingItems
                       genreShortcuts:(NSArray<MDBGenre *> *)genreShortcuts {
  self = [super init];
  if (self) {
    _trendingItems = [trendingItems copy];
    _genreShortcuts = [genreShortcuts copy];
  }
  return self;
}

@end

@interface MDBExploreViewModel ()
@property (nonatomic, readwrite) MDBObservable<NSNumber *> *mode;
@property (nonatomic, readwrite) MDBObservable<MDBScreenState<MDBExploreBrowseContent *> *> *browseState;
@property (nonatomic, readwrite) MDBObservable<MDBScreenState<MDBPagedItems *> *> *searchState;
@property (nonatomic, readonly) MDBSubject<NSString *> *querySubject;
@property (nonatomic, readonly) MDBSubject<MDBScreenState<NSArray<MDBMovie *> *> *> *trending;
@property (nonatomic, readonly) MDBSubject<NSArray<MDBGenre *> *> *genres;
@property (nonatomic, readonly) MDBMoviePager *pager;
@property (nonatomic, readonly) MDBExploreServices services;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic, nullable) id<MDBCancellable> trendingTask;
@property (nonatomic, nullable) id<MDBCancellable> genresTask;
/// The query the pager is currently showing, so a late debounce doesn't search it twice.
@property (nonatomic, copy, nullable) NSString *searchedQuery;
@end

@implementation MDBExploreViewModel

- (instancetype)initWithServices:(MDBExploreServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs
                     preferences:(MDBObservable<MDBPreferenceSnapshot *> *)preferences
                debounceInterval:(NSTimeInterval)debounceInterval {
  self = [super init];
  if (self) {
    _services = services;
    _bag = [[MDBDisposeBag alloc] init];
    _pager = [[MDBMoviePager alloc] init];
    _querySubject = [[MDBSubject alloc] initWithValue:@""];
    _trending = [[MDBSubject alloc] initWithValue:[MDBScreenState idle]];
    _genres = [[MDBSubject alloc] initWithValue:@[]];

    _mode = [[_querySubject map:^id(NSString *query) {
      return @(query.length > 0 ? MDBExploreModeSearch : MDBExploreModeBrowse);
    }] distinctUntilChanged];

    _browseState = [MDBObservable combineLatest:_trending with:_genres reduce:^id(MDBScreenState<NSArray<MDBMovie *> *> *state,
                                                                                  NSArray<MDBGenre *> *genres) {
      NSMutableDictionary<NSNumber *, NSString *> *names = [NSMutableDictionary dictionary];
      for (MDBGenre *genre in genres) {
        names[@(genre.genreID)] = genre.name;
      }
      NSArray<MDBGenre *> *shortcuts = [genres subarrayWithRange:NSMakeRange(0, MIN(genres.count, MDBGenreShortcutLimit))];
      return [state mapContent:^id(NSArray<MDBMovie *> *movies) {
        NSArray *items = [MDBMovieCellModel modelsWithMovies:movies genreNames:names imageURLs:imageURLs];
        return [[MDBExploreBrowseContent alloc] initWithTrendingItems:items genreShortcuts:shortcuts];
      }];
    }];

    _searchState = [MDBObservable combineLatest:_pager.state with:services.genreNames
                                         reduce:^id(MDBScreenState<MDBPagedMovies *> *state, NSDictionary *genreNames) {
                                           return [state mapContent:^id(MDBPagedMovies *page) {
                                             return [MDBPagedItems itemsFromPage:page genreNames:genreNames imageURLs:imageURLs];
                                           }];
                                         }];

    [self bindQueryWithDebounce:debounceInterval];
    [self bindPreferences:preferences];
  }
  return self;
}

- (void)dealloc {
  [_trendingTask cancel];
  [_genresTask cancel];
}

- (MDBObservable<NSString *> *)query {
  return self.querySubject;
}

#pragma mark - Bindings

- (void)bindQueryWithDebounce:(NSTimeInterval)interval {
  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[[[self.querySubject debounce:interval] distinctUntilChanged] subscribe:^(NSString *query) {
              __strong typeof(weakSelf) strongSelf = weakSelf;
              if (query.length > 0 && ![query isEqual:strongSelf.searchedQuery]) {
                [strongSelf searchFor:query];
              }
            }]];
}

- (void)bindPreferences:(MDBObservable<MDBPreferenceSnapshot *> *)preferences {
  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[[preferences skip:1] subscribe:^(id value) {
              __strong typeof(weakSelf) strongSelf = weakSelf;
              [strongSelf reloadBrowse];
              [strongSelf retrySearch];
            }]];
}

#pragma mark - Browse

- (void)loadIfNeeded {
  MDBLoadState phase = self.trending.value.phase;
  if (phase == MDBLoadStateIdle || phase == MDBLoadStateFailed) {
    [self reloadBrowse];
  }
}

- (void)reloadBrowse {
  MDBAssertMainThread();
  [self.trendingTask cancel];
  [self.genresTask cancel];
  [self.trending send:[MDBScreenState loadingWithContent:self.trending.value.content]];

  __weak typeof(self) weakSelf = self;
  self.genresTask = [self.services fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
    if (genres.count > 0) {
      [weakSelf.genres send:genres];
    }
  }];
  self.trendingTask = [self.services fetchMovieList:MDBMovieListKindTrending page:1
                                         completion:^(MDBPage<MDBMovie *> *page, NSError *error) {
                                           MDBSubject *trending = weakSelf.trending;
                                           if (error.mdb_isCancelled) {
                                             return;
                                           }
                                           if (!page) {
                                             [trending send:[MDBScreenState failedWithError:error content:nil]];
                                           } else if (page.results.count == 0) {
                                             [trending send:[MDBScreenState empty]];
                                           } else {
                                             [trending send:[MDBScreenState loadedWithContent:page.results]];
                                           }
                                         }];
}

#pragma mark - Search

- (void)updateQuery:(NSString *)query {
  MDBAssertMainThread();
  NSString *trimmed = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([trimmed isEqual:self.querySubject.value]) {
    return;
  }
  [self.querySubject send:trimmed];
  if (trimmed.length == 0) {
    self.searchedQuery = nil;
    [self.pager reset];
  } else if (![trimmed isEqual:self.searchedQuery]) {
    // Show the spinner while the debounce waits, so typing feels responsive.
    self.searchedQuery = nil;
    [self.pager showLoading];
  }
}

- (void)submitQuery {
  NSString *query = self.querySubject.value;
  if (query.length > 0) {
    [self searchFor:query];
  }
}

- (void)retrySearch {
  self.searchedQuery = nil;
  [self submitQuery];
}

- (void)searchFor:(NSString *)query {
  MDBLogDebug(MDBLogCategoryUI, @"Search \"%@\"", query);
  self.searchedQuery = query;
  id<MDBMovieSearching> searcher = self.services;
  [self.pager startWithRequest:^id<MDBCancellable>(NSInteger page, MDBMoviePageCompletion completion) {
    return [searcher searchMoviesWithQuery:query page:page completion:completion];
  }];
}

- (void)loadMoreResultsIfNeededForIndex:(NSInteger)index {
  [self.pager loadMoreIfNeededForIndex:index];
}

- (NSString *)resultsSummaryForItems:(MDBPagedItems *)items {
  NSString *noun = items.totalResults == 1 ? @"result" : @"results";
  return [NSString stringWithFormat:@"%ld %@ for ‘%@’", (long)items.totalResults, noun, self.querySubject.value ?: @""];
}

@end
