//
//  MDBMovieListViewModel.m
//  MovieDB
//

#import "MDBMovieListViewModel.h"
#import "MDBAPIError.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBPage.h"

/// Start loading the next page when the user is this many items from the end.
static const NSInteger MDBPrefetchDistance = 9;

@interface MDBMovieListViewModel ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, readwrite) MDBDiscoverSort sort;
@property (nonatomic, readwrite) MDBLoadState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic, readwrite) NSInteger totalResults;
@property (nonatomic, readwrite, getter=isLoadingMore) BOOL loadingMore;

@property (nonatomic, readonly) MDBMovieListKind kind;
@property (nonatomic, readonly, nullable) MDBGenre *genre;
@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, nullable) id<MDBCancellable> task;
@property (nonatomic) NSInteger page;
@property (nonatomic) NSInteger totalPages;
@property (nonatomic) NSUInteger generation;
@end

@implementation MDBMovieListViewModel

- (instancetype)initWithKind:(MDBMovieListKind)kind
                       genre:(nullable MDBGenre *)genre
                movieService:(id<MDBMovieService>)movieService
                   imageURLs:(MDBImageURLBuilder *)imageURLs {
    self = [super init];
    if (self) {
        _kind = kind;
        _genre = genre;
        _movieService = movieService;
        _imageURLs = imageURLs;
        _title = [(genre ? genre.name : MDBMovieListKindTitle(kind)) copy];
        _sort = MDBDiscoverSortPopularity;
        _items = @[];
    }
    return self;
}

- (instancetype)initWithListKind:(MDBMovieListKind)kind
                    movieService:(id<MDBMovieService>)movieService
                       imageURLs:(MDBImageURLBuilder *)imageURLs {
    return [self initWithKind:kind genre:nil movieService:movieService imageURLs:imageURLs];
}

- (instancetype)initWithGenre:(MDBGenre *)genre
                 movieService:(id<MDBMovieService>)movieService
                    imageURLs:(MDBImageURLBuilder *)imageURLs {
    return [self initWithKind:MDBMovieListKindPopular genre:genre movieService:movieService imageURLs:imageURLs];
}

- (void)dealloc {
    [_task cancel];
}

- (BOOL)showsSortOptions {
    return self.genre != nil;
}

- (NSArray<NSString *> *)sortTitles {
    return @[MDBDiscoverSortTitle(MDBDiscoverSortPopularity),
             MDBDiscoverSortTitle(MDBDiscoverSortRating),
             MDBDiscoverSortTitle(MDBDiscoverSortNewest)];
}

#pragma mark - Loading

- (void)loadFirstPage {
    [self.task cancel];
    self.generation += 1;
    self.page = 0;
    self.totalPages = 1;
    self.items = @[];
    self.loadingMore = NO;
    self.state = MDBLoadStateLoading;
    self.error = nil;
    [self notifyChange];
    [self requestPage:1];
}

- (void)loadMoreIfNeededForIndex:(NSInteger)index {
    if (self.state != MDBLoadStateLoaded || self.isLoadingMore || self.page >= self.totalPages) {
        return;
    }
    if (index < (NSInteger)self.items.count - MDBPrefetchDistance) {
        return;
    }
    self.loadingMore = YES;
    [self notifyChange];
    [self requestPage:self.page + 1];
}

- (void)selectSortAtIndex:(NSInteger)index {
    if (index < 0 || index > MDBDiscoverSortNewest || index == self.sort) {
        return;
    }
    self.sort = (MDBDiscoverSort)index;
    MDBLogInfo(MDBLogCategoryUI, @"%@ sorted by %@", self.title, MDBDiscoverSortTitle(self.sort));
    [self loadFirstPage];
}

- (void)requestPage:(NSInteger)page {
    NSUInteger generation = self.generation;
    __weak typeof(self) weakSelf = self;
    MDBMoviePageCompletion completion = ^(MDBPage<MDBMovie *> *result, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.generation != generation || error.mdb_isCancelled) {
            return;
        }
        [strongSelf handlePage:result error:error requestedPage:page];
    };
    if (self.genre) {
        self.task = [self.movieService discoverMoviesWithGenreID:self.genre.genreID sort:self.sort page:page completion:completion];
    } else {
        self.task = [self.movieService fetchMovieList:self.kind page:page completion:completion];
    }
}

- (void)handlePage:(nullable MDBPage<MDBMovie *> *)page error:(nullable NSError *)error requestedPage:(NSInteger)requestedPage {
    self.loadingMore = NO;
    MDBPage<MDBMovie *> *result = page;
    if (!result) {
        if (requestedPage == 1) {
            self.state = MDBLoadStateFailed;
            self.error = error;
        } else {
            MDBLogError(MDBLogCategoryUI, @"Page %ld of %@ failed: %@", (long)requestedPage, self.title, error.localizedDescription);
        }
        [self notifyChange];
        return;
    }

    id<MDBMovieService> service = self.movieService;
    NSArray<MDBMovieCellModel *> *models = [MDBMovieCellModel modelsWithMovies:result.results
                                                            genreNamesProvider:^NSArray<NSString *> *(NSArray<NSNumber *> *genreIDs) {
        return [service genreNamesForIDs:genreIDs];
    }
                                                                     imageURLs:self.imageURLs];
    NSMutableSet<NSNumber *> *seen = [NSMutableSet setWithCapacity:self.items.count];
    for (MDBMovieCellModel *model in self.items) {
        [seen addObject:@(model.movieID)];
    }
    NSMutableArray<MDBMovieCellModel *> *merged = [self.items mutableCopy];
    for (MDBMovieCellModel *model in models) {
        if (![seen containsObject:@(model.movieID)]) {
            [merged addObject:model];
        }
    }
    self.items = merged;
    self.page = result.page;
    self.totalPages = result.totalPages;
    self.totalResults = result.totalResults;
    self.state = merged.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
    [self notifyChange];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
