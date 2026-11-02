//
//  MDBMenuViewModel.m
//  MovieDB
//

#import "MDBMenuViewModel.h"
#import "MDBAPIError.h"
#import "MDBGenre.h"
#import "MDBObservable.h"
#import "MDBPreferences.h"
#import "MDBScreenState.h"

@interface MDBMenuViewModel ()
@property (nonatomic, readonly) MDBSubject<MDBScreenState<NSArray<MDBGenre *> *> *> *genresSubject;
@property (nonatomic, readwrite) MDBObservable<NSNumber *> *favoritesCount;
@property (nonatomic, readonly) id<MDBGenreProviding> genreProvider;
@property (nonatomic, readonly) MDBPreferences *preferenceStore;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic, nullable) id<MDBCancellable> genresTask;
@end

@implementation MDBMenuViewModel

- (instancetype)initWithGenreProvider:(id<MDBGenreProviding>)genreProvider
                          preferences:(MDBPreferences *)preferences
                       favoritesStore:(id<MDBFavoritesStore>)favoritesStore {
  self = [super init];
  if (self) {
    _genreProvider = genreProvider;
    _preferenceStore = preferences;
    _favoritesStore = favoritesStore;
    _bag = [[MDBDisposeBag alloc] init];
    _genresSubject = [[MDBSubject alloc] initWithValue:[MDBScreenState idle]];
    _favoritesCount = [[favoritesStore.favorites map:^id(NSArray *favorites) {
      return @(favorites.count);
    }] distinctUntilChanged];

    // Genre names come back translated, so fetch them again after a language change.
    __weak typeof(self) weakSelf = self;
    [_bag addDisposable:[[preferences.current skip:1] subscribe:^(id value) {
            [weakSelf reloadGenres];
          }]];
  }
  return self;
}

- (void)dealloc {
  [_genresTask cancel];
}

- (MDBObservable<MDBScreenState<NSArray<MDBGenre *> *> *> *)genresState {
  return self.genresSubject;
}

- (MDBObservable<MDBPreferenceSnapshot *> *)preferences {
  return self.preferenceStore.current;
}

- (NSArray<MDBPreferenceOption *> *)regionOptions {
  return MDBPreferences.regionOptions;
}

- (NSArray<MDBPreferenceOption *> *)languageOptions {
  return MDBPreferences.languageOptions;
}

- (void)loadIfNeeded {
  MDBLoadState phase = self.genresSubject.value.phase;
  if (phase == MDBLoadStateIdle || phase == MDBLoadStateFailed) {
    [self reloadGenres];
  }
}

- (void)reloadGenres {
  [self.genresTask cancel];
  MDBSubject<MDBScreenState<NSArray<MDBGenre *> *> *> *subject = self.genresSubject;
  [subject send:[MDBScreenState loadingWithContent:subject.value.content]];
  self.genresTask = [self.genreProvider fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
    if (error.mdb_isCancelled) {
      return;
    }
    if (!genres) {
      [subject send:[MDBScreenState failedWithError:error content:nil]];
    } else {
      [subject send:genres.count > 0 ? [MDBScreenState loadedWithContent:genres] : [MDBScreenState empty]];
    }
  }];
}

- (void)selectRegionCode:(NSString *)code {
  self.preferenceStore.regionCode = code;
}

- (void)selectLanguageCode:(NSString *)code {
  self.preferenceStore.languageCode = code;
}

- (void)clearFavorites {
  [self.favoritesStore removeAllFavoritesWithCompletion:nil];
}

@end
