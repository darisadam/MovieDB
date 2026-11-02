//
//  MDBMenuViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBGenre;
@class MDBPreferences;
@class MDBPreferenceOption;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMenuViewModel : NSObject

@property (nonatomic, readonly) MDBLoadState genresState;
@property (nonatomic, readonly, nullable) NSError *genresError;
@property (nonatomic, copy, readonly) NSArray<MDBGenre *> *genres;

@property (nonatomic, readonly) NSString *regionTitle;
@property (nonatomic, readonly) NSString *regionCode;
@property (nonatomic, readonly) NSString *languageTitle;
@property (nonatomic, readonly) NSString *languageCode;
@property (nonatomic, readonly) NSArray<MDBPreferenceOption *> *regionOptions;
@property (nonatomic, readonly) NSArray<MDBPreferenceOption *> *languageOptions;
@property (nonatomic, readonly) NSUInteger favoritesCount;

@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                         preferences:(MDBPreferences *)preferences
                      favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                  notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)loadIfNeeded;
- (void)reloadGenres;
- (void)selectRegionCode:(NSString *)code;
- (void)selectLanguageCode:(NSString *)code;
- (void)clearFavorites;

@end

NS_ASSUME_NONNULL_END
