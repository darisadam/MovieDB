//
//  MDBHomeViewModel.m
//  MovieDB
//

#import "MDBHomeViewModel.h"
#import "MDBAPIError.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBScreenState.h"

static const NSUInteger MDBCarouselLimit = 6;

/// Raw lists keyed by MDBMovieListKind, before they become cell models.
typedef NSDictionary<NSNumber *, NSArray<MDBMovie *> *> MDBHomeLists;

@implementation MDBHomeSection

- (instancetype)initWithKind:(MDBMovieListKind)kind items:(NSArray<MDBMovieCellModel *> *)items {
  self = [super init];
  if (self) {
    _kind = kind;
    _title = [MDBMovieListKindTitle(kind) copy];
    _items = [items copy];
  }
  return self;
}

@end

@implementation MDBHomeContent

- (instancetype)initWithCarouselItems:(NSArray<MDBMovieCellModel *> *)carouselItems
                             sections:(NSArray<MDBHomeSection *> *)sections {
  self = [super init];
  if (self) {
    _carouselItems = [carouselItems copy];
    _sections = [sections copy];
  }
  return self;
}

@end

@interface MDBHomeViewModel ()
@property (nonatomic, readwrite) MDBObservable<MDBScreenState<MDBHomeContent *> *> *state;
@property (nonatomic, readonly) MDBHomeServices services;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) MDBSubject<MDBScreenState<MDBHomeLists *> *> *lists;
@property (nonatomic, readonly) NSMutableArray<id<MDBCancellable>> *tasks;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic) NSUInteger generation;
@end

@implementation MDBHomeViewModel

- (instancetype)initWithServices:(MDBHomeServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs
                     preferences:(MDBObservable<MDBPreferenceSnapshot *> *)preferences {
  self = [super init];
  if (self) {
    _services = services;
    _imageURLs = imageURLs;
    _lists = [[MDBSubject alloc] initWithValue:[MDBScreenState idle]];
    _tasks = [NSMutableArray array];
    _bag = [[MDBDisposeBag alloc] init];

    // Genre names arrive separately, so the subtitles refresh when they do.
    __weak typeof(self) weakSelf = self;
    _state = [MDBObservable combineLatest:_lists with:services.genreNames
                                   reduce:^id(MDBScreenState<MDBHomeLists *> *lists, NSDictionary *genreNames) {
                                     return [weakSelf screenStateFromLists:lists genreNames:genreNames];
                                   }];

    [_bag addDisposable:[[preferences skip:1] subscribe:^(id value) {
            [weakSelf reload];
          }]];
  }
  return self;
}

- (void)dealloc {
  for (id<MDBCancellable> task in _tasks) {
    [task cancel];
  }
}

#pragma mark - Commands

- (void)loadIfNeeded {
  MDBLoadState phase = self.lists.value.phase;
  if (phase == MDBLoadStateIdle || phase == MDBLoadStateFailed) {
    [self reload];
  }
}

- (void)reload {
  MDBAssertMainThread();
  for (id<MDBCancellable> task in self.tasks) {
    [task cancel];
  }
  [self.tasks removeAllObjects];
  self.generation += 1;
  NSUInteger generation = self.generation;
  [self.lists send:[MDBScreenState loadingWithContent:self.lists.value.content]];

  if (self.services.genreNames.value.count == 0) {
    [self.tasks addObject:[self.services fetchGenresWithCompletion:^(NSArray *genres, NSError *error){
                          }]];
  }

  NSArray<NSNumber *> *kinds =
      @[ @(MDBMovieListKindNowPlaying), @(MDBMovieListKindPopular), @(MDBMovieListKindTopRated), @(MDBMovieListKindUpcoming) ];
  NSMutableDictionary<NSNumber *, NSArray<MDBMovie *> *> *results = [NSMutableDictionary dictionary];
  __block NSUInteger pending = kinds.count;
  __block NSError *firstError = nil;
  __weak typeof(self) weakSelf = self;

  for (NSNumber *kind in kinds) {
    id<MDBCancellable> task = [self.services fetchMovieList:(MDBMovieListKind)kind.integerValue page:1
                                                 completion:^(MDBPage<MDBMovie *> *page, NSError *error) {
                                                   __strong typeof(weakSelf) strongSelf = weakSelf;
                                                   if (!strongSelf || strongSelf.generation != generation) {
                                                     return;
                                                   }
                                                   if (page) {
                                                     results[kind] = page.results;
                                                   } else if (error && !error.mdb_isCancelled && !firstError) {
                                                     firstError = error;
                                                   }
                                                   pending -= 1;
                                                   if (pending == 0) {
                                                     [strongSelf finishWithResults:[results copy] error:firstError];
                                                   }
                                                 }];
    [self.tasks addObject:task];
  }
}

#pragma mark - State

- (void)finishWithResults:(MDBHomeLists *)results error:(nullable NSError *)error {
  BOOL hasMovies = NO;
  for (NSArray<MDBMovie *> *movies in results.allValues) {
    hasMovies = hasMovies || movies.count > 0;
  }
  if (hasMovies) {
    if (error) {
      MDBLogError(MDBLogCategoryUI, @"Home loaded with a missing section: %@", error.localizedDescription);
    }
    [self.lists send:[MDBScreenState loadedWithContent:results]];
  } else if (error) {
    [self.lists send:[MDBScreenState failedWithError:error content:nil]];
  } else {
    [self.lists send:[MDBScreenState empty]];
  }
  MDBLogInfo(MDBLogCategoryUI, @"Home %@", MDBLoadStateName(self.lists.value.phase));
}

- (MDBScreenState<MDBHomeContent *> *)screenStateFromLists:(MDBScreenState<MDBHomeLists *> *)lists
                                                genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames {
  MDBImageURLBuilder *imageURLs = self.imageURLs;
  return [lists mapContent:^id(MDBHomeLists *content) {
    NSMutableArray<MDBMovie *> *carouselMovies = [NSMutableArray array];
    for (MDBMovie *movie in content[@(MDBMovieListKindNowPlaying)]) {
      if (movie.backdropPath.length > 0 && carouselMovies.count < MDBCarouselLimit) {
        [carouselMovies addObject:movie];
      }
    }
    NSMutableArray<MDBHomeSection *> *sections = [NSMutableArray array];
    for (NSNumber *kind in @[ @(MDBMovieListKindPopular), @(MDBMovieListKindTopRated), @(MDBMovieListKindUpcoming) ]) {
      NSArray<MDBMovie *> *movies = content[kind];
      if (movies.count > 0) {
        NSArray<MDBMovieCellModel *> *items = [MDBMovieCellModel modelsWithMovies:movies genreNames:genreNames
                                                                        imageURLs:imageURLs];
        [sections addObject:[[MDBHomeSection alloc] initWithKind:(MDBMovieListKind)kind.integerValue items:items]];
      }
    }
    NSArray<MDBMovieCellModel *> *carousel = [MDBMovieCellModel modelsWithMovies:carouselMovies genreNames:genreNames
                                                                       imageURLs:imageURLs];
    return [[MDBHomeContent alloc] initWithCarouselItems:carousel sections:sections];
  }];
}

@end
