//
//  MDBAppDependencies.m
//  MovieDB
//

#import "MDBAppDependencies.h"
#import "MDBAPIClient.h"
#import "MDBCoreDataFavoritesStore.h"
#import "MDBCoreDataStack.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMetricsSubscriber.h"
#import "MDBNetworkActivityLog.h"
#import "MDBPreferences.h"
#import "MDBTMDBConfiguration.h"
#import "MDBTMDBMovieService.h"

@implementation MDBAppDependencies

+ (instancetype)liveDependencies {
    // Unit tests run inside the app, keep them away from the real favorites database.
    MDBCoreDataStoreType storeType = MDBIsRunningUnitTests() ? MDBCoreDataStoreTypeInMemory : MDBCoreDataStoreTypeSQLite;
    return [[self alloc] initWithConfiguration:[MDBTMDBConfiguration configurationWithBundle:[NSBundle mainBundle]]
                                  userDefaults:[NSUserDefaults standardUserDefaults]
                            notificationCenter:[NSNotificationCenter defaultCenter]
                                 coreDataStack:[[MDBCoreDataStack alloc] initWithStoreType:storeType]];
}

- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration
                         userDefaults:(NSUserDefaults *)userDefaults
                   notificationCenter:(NSNotificationCenter *)notificationCenter
                       coreDataStack:(MDBCoreDataStack *)coreDataStack {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _notificationCenter = notificationCenter;
        _networkLog = [[MDBNetworkActivityLog alloc] initWithCapacity:100];
        _apiClient = [[MDBAPIClient alloc] initWithConfiguration:configuration activityLog:_networkLog];
        _preferences = [[MDBPreferences alloc] initWithUserDefaults:userDefaults notificationCenter:notificationCenter];
        _movieService = [[MDBTMDBMovieService alloc] initWithClient:_apiClient preferences:_preferences];
        _imageURLs = [[MDBImageURLBuilder alloc] initWithBaseURL:configuration.imageBaseURL];
        _coreDataStack = coreDataStack;
        _favoritesStore = [[MDBCoreDataFavoritesStore alloc] initWithStack:coreDataStack notificationCenter:notificationCenter];
        _metrics = [[MDBMetricsSubscriber alloc] initWithDirectoryURL:[MDBMetricsSubscriber defaultDirectoryURL]];
        MDBLogInfo(MDBLogCategoryApp, @"Dependencies ready, %@", configuration);
    }
    return self;
}

@end
