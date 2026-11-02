//
//  MDBMoviePager.m
//  MovieDB
//

#import "MDBMoviePager.h"
#import "MDBAPIError.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBScreenState.h"

@implementation MDBPagedMovies

- (instancetype)initWithMovies:(NSArray<MDBMovie *> *)movies totalResults:(NSInteger)totalResults loadingMore:(BOOL)loadingMore {
  self = [super init];
  if (self) {
    _movies = [movies copy];
    _totalResults = totalResults;
    _loadingMore = loadingMore;
  }
  return self;
}

@end

@interface MDBMoviePager ()
@property (nonatomic, readonly) NSInteger prefetchDistance;
@property (nonatomic, readonly) MDBSubject<MDBScreenState<MDBPagedMovies *> *> *subject;
@property (nonatomic, copy, nullable) MDBMoviePageRequest request;
@property (nonatomic, nullable) id<MDBCancellable> task;
@property (nonatomic, copy) NSArray<MDBMovie *> *movies;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic) NSInteger totalResults;
@property (nonatomic) BOOL loadingMore;
@property (nonatomic) NSUInteger generation;
@end

@implementation MDBMoviePager

- (instancetype)init {
  return [self initWithPrefetchDistance:6];
}

- (instancetype)initWithPrefetchDistance:(NSInteger)prefetchDistance {
  self = [super init];
  if (self) {
    _prefetchDistance = MAX(0, prefetchDistance);
    _subject = [[MDBSubject alloc] initWithValue:[MDBScreenState idle]];
    _movies = @[];
  }
  return self;
}

- (void)dealloc {
  [_task cancel];
}

- (MDBObservable<MDBScreenState<MDBPagedMovies *> *> *)state {
  return self.subject;
}

#pragma mark - Commands

- (void)reset {
  [self clear];
  [self.subject send:[MDBScreenState idle]];
}

- (void)showLoading {
  [self clear];
  [self.subject send:[MDBScreenState loadingWithContent:nil]];
}

- (void)startWithRequest:(MDBMoviePageRequest)request {
  MDBAssertMainThread();
  [self clear];
  self.request = request;
  [self.subject send:[MDBScreenState loadingWithContent:nil]];
  [self requestPage:1];
}

- (void)loadMoreIfNeededForIndex:(NSInteger)index {
  if (!self.request || self.loadingMore || self.subject.value.phase != MDBLoadStateLoaded) {
    return;
  }
  if (self.page >= self.totalPages || index < (NSInteger)self.movies.count - self.prefetchDistance) {
    return;
  }
  self.loadingMore = YES;
  [self publishLoaded];
  [self requestPage:self.page + 1];
}

#pragma mark - Private

- (void)clear {
  [self.task cancel];
  self.task = nil;
  self.request = nil;
  self.generation += 1;
  self.movies = @[];
  self.page = 0;
  self.totalPages = 0;
  self.totalResults = 0;
  self.loadingMore = NO;
}

- (void)requestPage:(NSInteger)page {
  MDBMoviePageRequest request = self.request;
  if (!request) {
    return;
  }
  NSUInteger generation = self.generation;
  __weak typeof(self) weakSelf = self;
  self.task = request(page, ^(MDBPage<MDBMovie *> *result, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    // A reset or a new request happened while this one was in flight.
    if (!strongSelf || strongSelf.generation != generation || error.mdb_isCancelled) {
      return;
    }
    [strongSelf handlePage:result error:error requestedPage:page];
  });
}

- (void)handlePage:(nullable MDBPage<MDBMovie *> *)page error:(nullable NSError *)error requestedPage:(NSInteger)requestedPage {
  self.loadingMore = NO;
  MDBPage<MDBMovie *> *result = page;
  if (!result) {
    if (requestedPage == 1) {
      [self.subject send:[MDBScreenState failedWithError:error content:nil]];
    } else {
      // Keep what we have, the next scroll will try again.
      MDBLogError(MDBLogCategoryUI, @"Page %ld failed: %@", (long)requestedPage, error.localizedDescription);
      [self publishLoaded];
    }
    return;
  }

  NSMutableSet<NSNumber *> *seen = [NSMutableSet setWithCapacity:self.movies.count];
  for (MDBMovie *movie in self.movies) {
    [seen addObject:@(movie.movieID)];
  }
  NSMutableArray<MDBMovie *> *merged = [self.movies mutableCopy];
  for (MDBMovie *movie in result.results) {
    if (![seen containsObject:@(movie.movieID)]) {
      [seen addObject:@(movie.movieID)];
      [merged addObject:movie];
    }
  }
  self.movies = merged;
  self.page = result.page;
  self.totalPages = result.totalPages;
  self.totalResults = result.totalResults;

  if (merged.count == 0) {
    [self.subject send:[MDBScreenState empty]];
  } else {
    [self publishLoaded];
  }
}

- (void)publishLoaded {
  MDBPagedMovies *content = [[MDBPagedMovies alloc] initWithMovies:self.movies totalResults:self.totalResults
                                                       loadingMore:self.loadingMore];
  [self.subject send:[MDBScreenState loadedWithContent:content]];
}

@end
