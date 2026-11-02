//
//  MDBAppDependencies.h
//  MovieDB
//
//  The composition root. Everything long lived is created here once and handed down
//  through the coordinators. Nothing else in the app reaches for a shared instance.
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBMovieService.h"

@class MDBAPIClient;
@class MDBCoreDataStack;
@class MDBImageURLBuilder;
@class MDBMetricsSubscriber;
@class MDBNetworkActivityLog;
@class MDBPreferences;
@class MDBTMDBConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface MDBAppDependencies : NSObject

@property (nonatomic, readonly) MDBTMDBConfiguration *configuration;
@property (nonatomic, readonly) MDBNetworkActivityLog *networkLog;
@property (nonatomic, readonly) MDBAPIClient *apiClient;
@property (nonatomic, readonly) MDBPreferences *preferences;
@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) MDBCoreDataStack *coreDataStack;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) MDBMetricsSubscriber *metrics;

+ (instancetype)liveDependencies;

- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration
                         userDefaults:(NSUserDefaults *)userDefaults
                        coreDataStack:(MDBCoreDataStack *)coreDataStack NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
