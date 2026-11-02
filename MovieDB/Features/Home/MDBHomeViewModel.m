//
//  MDBHomeViewModel.m
//  MovieDB
//

#import "MDBHomeViewModel.h"
#import "MDBAPIError.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBPage.h"
#import "MDBPreferences.h"

static const NSUInteger MDBCarouselLimit = 6;

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

@interface MDBHomeViewModel ()
@property (nonatomic, readwrite) MDBLoadState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *carouselItems;
@property (nonatomic, copy, readwrite) NSArray<MDBHomeSection *> *sections;

@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, readonly) NSMutableArray<id<MDBCancellable>> *tasks;
@property (nonatomic, copy) NSDictionary<NSNumber *, NSArray<MDBMovie *> *> *lastResults;
@property (nonatomic) NSUInteger generation;
@property (nonatomic) id preferencesObserver;
@end

@implementation MDBHomeViewModel

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                           imageURLs:(MDBImageURLBuilder *)imageURLs
                  notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        _movieService = movieService;
        _imageURLs = imageURLs;
        _notificationCenter = notificationCenter;
        _tasks = [NSMutableArray array];
        _carouselItems = @[];
        _sections = @[];
        _lastResults = @{};
        _state = MDBLoadStateIdle;

        __weak typeof(self) weakSelf = self;
        _preferencesObserver = [notificationCenter addObserverForName:MDBPreferencesDidChangeNotification
                                                               object:nil
                                                                queue:[NSOperationQueue mainQueue]
                                                           usingBlock:^(NSNotification *note) {
            [weakSelf reload];
        }];
    }
    return self;
}

- (void)dealloc {
    for (id<MDBCancellable> task in _tasks) {
        [task cancel];
    }
    if (_preferencesObserver) {
        [_notificationCenter removeObserver:_preferencesObserver];
    }
}

- (void)loadIfNeeded {
    if (self.state == MDBLoadStateIdle || self.state == MDBLoadStateFailed) {
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

    self.state = MDBLoadStateLoading;
    self.error = nil;
    [self notifyChange];

    NSArray<NSNumber *> *kinds = @[@(MDBMovieListKindNowPlaying), @(MDBMovieListKindPopular),
                                   @(MDBMovieListKindTopRated), @(MDBMovieListKindUpcoming)];
    NSMutableDictionary<NSNumber *, NSArray<MDBMovie *> *> *results = [NSMutableDictionary dictionary];
    __block NSUInteger pending = kinds.count;
    __block NSError *firstError = nil;
    __weak typeof(self) weakSelf = self;

    // Genre names are nice to have for the carousel subtitle, so they load alongside and refresh the text when they land.
    [self.tasks addObject:[self.movieService fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.generation != generation || genres.count == 0) {
            return;
        }
        if (strongSelf.lastResults.count > 0) {
            [strongSelf buildContentFromResults:strongSelf.lastResults];
            [strongSelf notifyChange];
        }
    }]];

    for (NSNumber *kindNumber in kinds) {
        id<MDBCancellable> task = [self.movieService fetchMovieList:(MDBMovieListKind)kindNumber.integerValue
                                                               page:1
                                                         completion:^(MDBPage<MDBMovie *> *page, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf.generation != generation) {
                return;
            }
            if (page) {
                results[kindNumber] = page.results;
            } else if (error && !error.mdb_isCancelled && !firstError) {
                firstError = error;
            }
            pending -= 1;
            if (pending == 0) {
                [strongSelf finishWithResults:results error:firstError];
            }
        }];
        [self.tasks addObject:task];
    }
}

- (void)finishWithResults:(NSDictionary<NSNumber *, NSArray<MDBMovie *> *> *)results error:(nullable NSError *)error {
    self.lastResults = results;
    [self buildContentFromResults:results];
    BOOL hasContent = self.carouselItems.count > 0 || self.sections.count > 0;

    if (hasContent) {
        self.state = MDBLoadStateLoaded;
        self.error = nil;
        if (error) {
            MDBLogError(MDBLogCategoryUI, @"Home loaded with a missing section: %@", error.localizedDescription);
        }
    } else if (error) {
        self.state = MDBLoadStateFailed;
        self.error = error;
    } else {
        self.state = MDBLoadStateEmpty;
    }
    MDBLogInfo(MDBLogCategoryUI, @"Home %@ with %lu carousel items and %lu sections",
               MDBLoadStateName(self.state), (unsigned long)self.carouselItems.count, (unsigned long)self.sections.count);
    [self notifyChange];
}

- (void)buildContentFromResults:(NSDictionary<NSNumber *, NSArray<MDBMovie *> *> *)results {
    id<MDBMovieService> service = self.movieService;
    NSArray<NSString *> * (^genres)(NSArray<NSNumber *> *) = ^NSArray<NSString *> *(NSArray<NSNumber *> *genreIDs) {
        return [service genreNamesForIDs:genreIDs];
    };

    NSMutableArray<MDBMovie *> *carouselMovies = [NSMutableArray array];
    for (MDBMovie *movie in results[@(MDBMovieListKindNowPlaying)]) {
        if (movie.backdropPath.length > 0) {
            [carouselMovies addObject:movie];
        }
        if (carouselMovies.count == MDBCarouselLimit) {
            break;
        }
    }
    self.carouselItems = [MDBMovieCellModel modelsWithMovies:carouselMovies genreNamesProvider:genres imageURLs:self.imageURLs];

    NSMutableArray<MDBHomeSection *> *sections = [NSMutableArray array];
    for (NSNumber *kind in @[@(MDBMovieListKindPopular), @(MDBMovieListKindTopRated), @(MDBMovieListKindUpcoming)]) {
        NSArray<MDBMovie *> *movies = results[kind];
        if (movies.count == 0) {
            continue;
        }
        NSArray<MDBMovieCellModel *> *items = [MDBMovieCellModel modelsWithMovies:movies genreNamesProvider:genres imageURLs:self.imageURLs];
        [sections addObject:[[MDBHomeSection alloc] initWithKind:(MDBMovieListKind)kind.integerValue items:items]];
    }
    self.sections = sections;
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
