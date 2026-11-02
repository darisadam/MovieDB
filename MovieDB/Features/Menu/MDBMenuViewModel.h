//
//  MDBMenuViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBMovieService.h"

@class MDBGenre;
@class MDBObservable<ObjectType>;
@class MDBPreferenceOption;
@class MDBPreferences;
@class MDBPreferenceSnapshot;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMenuViewModel : NSObject

@property (nonatomic, readonly) MDBObservable<MDBScreenState<NSArray<MDBGenre *> *> *> *genresState;
@property (nonatomic, readonly) MDBObservable<MDBPreferenceSnapshot *> *preferences;
/// NSNumber with the number of saved favorites.
@property (nonatomic, readonly) MDBObservable<NSNumber *> *favoritesCount;

@property (nonatomic, readonly) NSArray<MDBPreferenceOption *> *regionOptions;
@property (nonatomic, readonly) NSArray<MDBPreferenceOption *> *languageOptions;

- (instancetype)initWithGenreProvider:(id<MDBGenreProviding>)genreProvider
                          preferences:(MDBPreferences *)preferences
                       favoritesStore:(id<MDBFavoritesStore>)favoritesStore NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadIfNeeded;
- (void)reloadGenres;
- (void)selectRegionCode:(NSString *)code;
- (void)selectLanguageCode:(NSString *)code;
- (void)clearFavorites;

@end

NS_ASSUME_NONNULL_END
