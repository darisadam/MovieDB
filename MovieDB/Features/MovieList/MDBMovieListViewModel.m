//
//  MDBMovieListViewModel.m
//  MovieDB
//

#import "MDBMovieListViewModel.h"
#import "MDBGenre.h"
#import "MDBLog.h"
#import "MDBMoviePager.h"
#import "MDBObservable.h"
#import "MDBPagedItems.h"
#import "MDBScreenState.h"

@interface MDBMovieListViewModel ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, readwrite) MDBObservable<MDBScreenState<MDBPagedItems *> *> *state;
@property (nonatomic, readonly) MDBSubject<NSNumber *> *sortSubject;
@property (nonatomic, readonly) MDBMovieListKind kind;
@property (nonatomic, readonly, nullable) MDBGenre *genre;
@property (nonatomic, readonly) MDBMovieListServices services;
@property (nonatomic, readonly) MDBMoviePager *pager;
@end

@implementation MDBMovieListViewModel

- (instancetype)initWithKind:(MDBMovieListKind)kind
                       genre:(nullable MDBGenre *)genre
                    services:(MDBMovieListServices)services
                   imageURLs:(MDBImageURLBuilder *)imageURLs {
  self = [super init];
  if (self) {
    _kind = kind;
    _genre = genre;
    _services = services;
    _title = [(genre ? genre.name : MDBMovieListKindTitle(kind)) copy];
    _sortSubject = [[MDBSubject alloc] initWithValue:@(MDBDiscoverSortPopularity)];
    _pager = [[MDBMoviePager alloc] initWithPrefetchDistance:9];
    _state = [MDBObservable combineLatest:_pager.state with:services.genreNames
                                   reduce:^id(MDBScreenState<MDBPagedMovies *> *state, NSDictionary *genreNames) {
                                     return [state mapContent:^id(MDBPagedMovies *page) {
                                       return [MDBPagedItems itemsFromPage:page genreNames:genreNames imageURLs:imageURLs];
                                     }];
                                   }];
  }
  return self;
}

- (instancetype)initWithListKind:(MDBMovieListKind)kind
                        services:(MDBMovieListServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs {
  return [self initWithKind:kind genre:nil services:services imageURLs:imageURLs];
}

- (instancetype)initWithGenre:(MDBGenre *)genre
                     services:(MDBMovieListServices)services
                    imageURLs:(MDBImageURLBuilder *)imageURLs {
  return [self initWithKind:MDBMovieListKindPopular genre:genre services:services imageURLs:imageURLs];
}

- (BOOL)showsSortOptions {
  return self.genre != nil;
}

- (NSArray<NSString *> *)sortTitles {
  return @[
    MDBDiscoverSortTitle(MDBDiscoverSortPopularity), MDBDiscoverSortTitle(MDBDiscoverSortRating),
    MDBDiscoverSortTitle(MDBDiscoverSortNewest)
  ];
}

- (MDBObservable<NSNumber *> *)sort {
  return self.sortSubject;
}

- (void)loadFirstPage {
  id<MDBMovieListProviding> provider = self.services;
  MDBMovieListKind kind = self.kind;
  MDBGenre *genre = self.genre;
  MDBDiscoverSort sort = (MDBDiscoverSort)self.sortSubject.value.integerValue;
  [self.pager startWithRequest:^id<MDBCancellable>(NSInteger page, MDBMoviePageCompletion completion) {
    if (genre) {
      return [provider discoverMoviesWithGenreID:genre.genreID sort:sort page:page completion:completion];
    }
    return [provider fetchMovieList:kind page:page completion:completion];
  }];
}

- (void)loadMoreIfNeededForIndex:(NSInteger)index {
  [self.pager loadMoreIfNeededForIndex:index];
}

- (void)selectSortAtIndex:(NSInteger)index {
  if (index < MDBDiscoverSortPopularity || index > MDBDiscoverSortNewest || index == self.sortSubject.value.integerValue) {
    return;
  }
  [self.sortSubject send:@(index)];
  MDBLogInfo(MDBLogCategoryUI, @"%@ sorted by %@", self.title, MDBDiscoverSortTitle((MDBDiscoverSort)index));
  [self loadFirstPage];
}

@end
