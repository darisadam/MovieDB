//
//  MDBMenuViewModel.m
//  MovieDB
//

#import "MDBMenuViewModel.h"
#import "MDBAPIError.h"
#import "MDBGenre.h"
#import "MDBPreferences.h"

@interface MDBMenuViewModel ()
@property (nonatomic, readwrite) MDBLoadState genresState;
@property (nonatomic, readwrite, nullable) NSError *genresError;
@property (nonatomic, copy, readwrite) NSArray<MDBGenre *> *genres;
@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBPreferences *preferences;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic, nullable) id<MDBCancellable> genresTask;
@property (nonatomic, copy) NSArray *observers;
@end

@implementation MDBMenuViewModel

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                         preferences:(MDBPreferences *)preferences
                      favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                  notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        _movieService = movieService;
        _preferences = preferences;
        _favoritesStore = favoritesStore;
        _notificationCenter = notificationCenter;
        _genres = @[];

        __weak typeof(self) weakSelf = self;
        id favorites = [notificationCenter addObserverForName:MDBFavoritesDidChangeNotification
                                                       object:nil
                                                        queue:[NSOperationQueue mainQueue]
                                                   usingBlock:^(NSNotification *note) {
            [weakSelf notifyChange];
        }];
        id preferencesObserver = [notificationCenter addObserverForName:MDBPreferencesDidChangeNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
            // Genre names come back translated, so fetch them again.
            [weakSelf reloadGenres];
        }];
        _observers = @[favorites, preferencesObserver];
    }
    return self;
}

- (void)dealloc {
    [_genresTask cancel];
    for (id observer in _observers) {
        [_notificationCenter removeObserver:observer];
    }
}

- (void)loadIfNeeded {
    if (self.genresState == MDBLoadStateIdle || self.genresState == MDBLoadStateFailed) {
        [self reloadGenres];
    }
}

- (void)reloadGenres {
    [self.genresTask cancel];
    self.genresState = MDBLoadStateLoading;
    self.genresError = nil;
    [self notifyChange];

    __weak typeof(self) weakSelf = self;
    self.genresTask = [self.movieService fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || error.mdb_isCancelled) {
            return;
        }
        if (genres) {
            strongSelf.genres = genres;
            strongSelf.genresState = genres.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
        } else {
            strongSelf.genresState = MDBLoadStateFailed;
            strongSelf.genresError = error;
        }
        [strongSelf notifyChange];
    }];
}

- (NSString *)regionTitle { return [self.preferences regionTitle]; }
- (NSString *)regionCode { return self.preferences.regionCode; }
- (NSString *)languageTitle { return [self.preferences languageTitle]; }
- (NSString *)languageCode { return self.preferences.languageCode; }
- (NSArray<MDBPreferenceOption *> *)regionOptions { return MDBPreferences.regionOptions; }
- (NSArray<MDBPreferenceOption *> *)languageOptions { return MDBPreferences.languageOptions; }
- (NSUInteger)favoritesCount { return [self.favoritesStore favoritesCount]; }

- (void)selectRegionCode:(NSString *)code {
    self.preferences.regionCode = code;
    [self notifyChange];
}

- (void)selectLanguageCode:(NSString *)code {
    self.preferences.languageCode = code;
    [self notifyChange];
}

- (void)clearFavorites {
    [self.favoritesStore removeAllFavoritesWithCompletion:nil];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
