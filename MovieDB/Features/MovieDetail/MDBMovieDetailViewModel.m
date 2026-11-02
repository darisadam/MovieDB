//
//  MDBMovieDetailViewModel.m
//  MovieDB
//

#import "MDBMovieDetailViewModel.h"
#import "MDBAPIError.h"
#import "MDBCastCell.h"
#import "MDBCastMember.h"
#import "MDBFormatting.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetail.h"
#import "MDBVideo.h"

@implementation MDBMovieFact

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value {
    self = [super init];
    if (self) {
        _title = [title copy];
        _value = [value copy];
    }
    return self;
}

@end

@interface MDBMovieDetailViewModel ()
@property (nonatomic, readwrite) MDBLoadState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@property (nonatomic, readwrite, nullable) MDBMovieDetail *detail;
@property (nonatomic, readwrite, getter=isFavorite) BOOL favorite;
@property (nonatomic, readonly, nullable) MDBMovie *seedMovie;
@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, nullable) id<MDBCancellable> task;
@property (nonatomic) id favoritesObserver;
@end

@implementation MDBMovieDetailViewModel

- (instancetype)initWithMovieID:(NSInteger)movieID
                       seedMovie:(nullable MDBMovie *)seedMovie
                    movieService:(id<MDBMovieService>)movieService
                  favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                       imageURLs:(MDBImageURLBuilder *)imageURLs
              notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        _movieID = movieID;
        _seedMovie = seedMovie;
        _movieService = movieService;
        _favoritesStore = favoritesStore;
        _imageURLs = imageURLs;
        _notificationCenter = notificationCenter;
        _favorite = [favoritesStore isFavoriteMovieID:movieID];

        __weak typeof(self) weakSelf = self;
        _favoritesObserver = [notificationCenter addObserverForName:MDBFavoritesDidChangeNotification
                                                             object:nil
                                                              queue:[NSOperationQueue mainQueue]
                                                         usingBlock:^(NSNotification *note) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            BOOL isFavorite = [strongSelf.favoritesStore isFavoriteMovieID:strongSelf.movieID];
            if (isFavorite != strongSelf.favorite) {
                strongSelf.favorite = isFavorite;
                [strongSelf notifyChange];
            }
        }];
    }
    return self;
}

- (void)dealloc {
    [_task cancel];
    if (_favoritesObserver) {
        [_notificationCenter removeObserver:_favoritesObserver];
    }
}

#pragma mark - Loading

- (void)load {
    MDBAssertMainThread();
    [self.task cancel];
    self.state = MDBLoadStateLoading;
    self.error = nil;
    [self notifyChange];

    __weak typeof(self) weakSelf = self;
    self.task = [self.movieService fetchMovieDetailWithID:self.movieID completion:^(MDBMovieDetail *detail, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || error.mdb_isCancelled) {
            return;
        }
        if (detail) {
            strongSelf.detail = detail;
            strongSelf.state = MDBLoadStateLoaded;
            MDBLogInfo(MDBLogCategoryUI, @"Detail loaded %@", detail);
        } else {
            strongSelf.state = MDBLoadStateFailed;
            strongSelf.error = error;
        }
        [strongSelf notifyChange];
    }];
}

- (void)toggleFavorite {
    MDBMovie *movie = self.detail.movie ?: self.seedMovie;
    if (!movie) {
        return;
    }
    // Flip the button right away, the store notification confirms it a moment later.
    BOOL newValue = !self.favorite;
    self.favorite = newValue;
    [self notifyChange];

    __weak typeof(self) weakSelf = self;
    MDBFavoritesCompletion completion = ^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (error && strongSelf) {
            strongSelf.favorite = !newValue;
            [strongSelf notifyChange];
        }
    };
    if (newValue) {
        [self.favoritesStore addFavoriteMovie:movie genreNames:self.genreNames completion:completion];
    } else {
        [self.favoritesStore removeFavoriteWithMovieID:self.movieID completion:completion];
    }
}

#pragma mark - Display values

- (MDBMovie *_Nullable)currentMovie {
    return self.detail.movie ?: self.seedMovie;
}

- (NSString *)title {
    return [self currentMovie].title ?: @"";
}

- (nullable NSURL *)backdropURL {
    MDBMovie *movie = [self currentMovie];
    // A tall poster looks better than a cropped backdrop in this header.
    return [self.imageURLs URLForPath:movie.posterPath size:MDBImageSizeBackdrop]
        ?: [self.imageURLs URLForPath:movie.backdropPath size:MDBImageSizeBackdrop];
}

- (NSString *)metaText {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSString *year = [MDBFormatting yearStringFromDate:[self currentMovie].releaseDate];
    if (year.length > 0) {
        [parts addObject:year];
    }
    NSString *runtime = [MDBFormatting runtimeStringFromMinutes:self.detail.runtimeMinutes];
    if (runtime.length > 0) {
        [parts addObject:runtime];
    }
    return [parts componentsJoinedByString:@"  ·  "];
}

- (nullable NSString *)ratingText {
    MDBMovie *movie = [self currentMovie];
    return movie.voteCount > 0 ? [MDBFormatting ratingStringFromVoteAverage:movie.voteAverage] : nil;
}

- (nullable NSString *)tagline {
    return self.detail.tagline;
}

- (NSString *)overview {
    NSString *overview = [self currentMovie].overview;
    return overview.length > 0 ? overview : @"No overview yet.";
}

- (NSArray<NSString *> *)genreNames {
    if (self.detail) {
        NSMutableArray<NSString *> *names = [NSMutableArray array];
        for (MDBGenre *genre in self.detail.genres) {
            [names addObject:genre.name];
        }
        return names;
    }
    MDBMovie *seed = self.seedMovie;
    return seed ? [self.movieService genreNamesForIDs:seed.genreIDs] : @[];
}

- (NSArray<MDBMovieFact *> *)facts {
    MDBMovieDetail *detail = self.detail;
    if (!detail) {
        return @[];
    }
    NSMutableArray<MDBMovieFact *> *facts = [NSMutableArray array];
    NSString *release = [MDBFormatting mediumDateStringFromDate:detail.movie.releaseDate];
    [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Release" value:release.length > 0 ? release : @"TBA"]];
    NSString *language = detail.originalLanguageName;
    if (language.length > 0) {
        [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Language" value:language]];
    }
    NSString *budget = [MDBFormatting compactCurrencyStringFromAmount:detail.budget];
    if (budget.length > 0) {
        [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Budget" value:budget]];
    } else {
        NSString *status = detail.status;
        if (status.length > 0) {
            [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Status" value:status]];
        }
    }
    return facts;
}

- (NSArray<MDBCastCellModel *> *)cast {
    NSMutableArray<MDBCastCellModel *> *models = [NSMutableArray array];
    for (MDBCastMember *member in self.detail.cast) {
        [models addObject:[[MDBCastCellModel alloc] initWithPersonID:member.personID
                                                                name:member.name
                                                           character:member.character
                                                            photoURL:[self.imageURLs URLForPath:member.profilePath size:MDBImageSizeProfile]]];
    }
    return models;
}

- (NSArray<MDBMovieCellModel *> *)recommendations {
    id<MDBMovieService> service = self.movieService;
    return [MDBMovieCellModel modelsWithMovies:self.detail.recommendations ?: @[]
                            genreNamesProvider:^NSArray<NSString *> *(NSArray<NSNumber *> *genreIDs) {
        return [service genreNamesForIDs:genreIDs];
    }
                                     imageURLs:self.imageURLs];
}

- (NSArray<MDBVideo *> *)videos {
    return self.detail.videos ?: @[];
}

- (BOOL)hasTrailer {
    return self.videos.count > 0;
}

- (nullable NSURL *)shareURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://www.themoviedb.org/movie/%ld", (long)self.movieID]];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
