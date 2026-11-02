//
//  MDBCoordinatorAndLeakTests.m
//  MovieDBTests
//
//  Navigation through the real coordinators, and checks that screens and view models
//  are released when they go away. Uses real dependencies with an empty token and an
//  in-memory store, so nothing touches the network or disk.
//

#import <XCTest/XCTest.h>
#import "MDBAboutViewController.h"
#import "MDBAppDependencies.h"
#import "MDBCoreDataStack.h"
#import "MDBExploreViewController.h"
#import "MDBExploreViewModel.h"
#import "MDBFavoritesViewController.h"
#import "MDBFavoritesViewModel.h"
#import "MDBGenre.h"
#import "MDBHomeViewController.h"
#import "MDBHomeViewModel.h"
#import "MDBMenuViewController.h"
#import "MDBMenuViewModel.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetailViewController.h"
#import "MDBMovieDetailViewModel.h"
#import "MDBMovieFlowCoordinator.h"
#import "MDBMovieListViewController.h"
#import "MDBMovieListViewModel.h"
#import "MDBPersonViewController.h"
#import "MDBPersonViewModel.h"
#import "MDBPreferences.h"
#import "MDBTMDBConfiguration.h"
#import "MDBTestSupport.h"

@interface MDBCoordinatorAndLeakTests : XCTestCase
@property (nonatomic) MDBAppDependencies *dependencies;
@property (nonatomic) UINavigationController *navigationController;
@property (nonatomic) MDBMovieFlowCoordinator *coordinator;
@property (nonatomic, copy) NSString *suiteName;
@end

@implementation MDBCoordinatorAndLeakTests

- (void)setUp {
  [super setUp];
  self.suiteName = [NSString stringWithFormat:@"MovieDBTests.%@", [NSUUID UUID].UUIDString];
  MDBTMDBConfiguration *configuration = [[MDBTMDBConfiguration alloc] initWithAccessToken:@""
                                                                               apiBaseURL:MDBTestURL(@"https://api.themoviedb.org/3/")
                                                                             imageBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
  self.dependencies = [[MDBAppDependencies alloc] initWithConfiguration:configuration
                                                            userDefaults:MDBTestDefaults(self.suiteName)
                                                           coreDataStack:[[MDBCoreDataStack alloc] initWithStoreType:MDBCoreDataStoreTypeInMemory]];
  self.navigationController = [[UINavigationController alloc] init];
  self.coordinator = [[MDBMovieFlowCoordinator alloc] initWithNavigationController:self.navigationController dependencies:self.dependencies];
}

- (void)tearDown {
  [[[NSUserDefaults alloc] initWithSuiteName:self.suiteName] removePersistentDomainForName:self.suiteName];
  [super tearDown];
}

- (MDBMovieCellModel *)cellModel {
  return [MDBMovieCellModel modelsWithMovies:@[ MDBTestMovie(7, @"Seven") ] genreNames:nil imageURLs:self.dependencies.imageURLs].firstObject;
}

#pragma mark - Navigation

- (void)testShowMoviePushesDetailWithDelegate {
  [self.coordinator showMovie:[self cellModel]];
  MDBMovieDetailViewController *top = (MDBMovieDetailViewController *)self.navigationController.viewControllers.lastObject;
  XCTAssertTrue([top isKindOfClass:[MDBMovieDetailViewController class]]);
  XCTAssertEqual(top.delegate, (id)self.coordinator);
  XCTAssertEqual(top.viewModel.movieID, 7);
}

// One push per test. iOS 17 drops a second animated push while the first transition is running.

- (void)testShowGenrePushesListScreen {
  [self.coordinator showGenre:[[MDBGenre alloc] initWithGenreID:28 name:@"Action"]];
  UIViewController *top = self.navigationController.viewControllers.lastObject;
  XCTAssertTrue([top isKindOfClass:[MDBMovieListViewController class]]);
  XCTAssertEqualObjects(top.title, @"Action");
}

- (void)testShowMovieListPushesListScreen {
  [self.coordinator showMovieList:MDBMovieListKindUpcoming];
  UIViewController *top = self.navigationController.viewControllers.lastObject;
  XCTAssertTrue([top isKindOfClass:[MDBMovieListViewController class]]);
  XCTAssertEqualObjects(top.title, @"Upcoming");
}

- (void)testShowPersonPushesPersonScreen {
  [self.coordinator showPersonWithID:10980 name:@"Daniel Radcliffe"];
  XCTAssertTrue([self.navigationController.viewControllers.lastObject isKindOfClass:[MDBPersonViewController class]]);
}

- (void)testShowAboutPushesAboutWithDelegate {
  [self.coordinator showAbout];
  MDBAboutViewController *about = (MDBAboutViewController *)self.navigationController.viewControllers.lastObject;
  XCTAssertTrue([about isKindOfClass:[MDBAboutViewController class]]);
  XCTAssertEqual(about.delegate, (id)self.coordinator);
}

#pragma mark - Leaks

/// Builds the screen, loads its view so all bindings run, then checks it goes away.
- (void)assertReleased:(UIViewController * (^)(void))makeController name:(NSString *)name {
  __weak UIViewController *weakController = nil;
  @autoreleasepool {
    UIViewController *controller = makeController();
    [controller loadViewIfNeeded];
    [controller viewWillAppear:NO];
    weakController = controller;
  }
  // Give pending main queue work (like the missing token errors) a moment to run.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  XCTAssertNil(weakController, @"%@ is kept alive, probably by a block or a subscription", name);
}

- (void)testScreensAreReleased {
  MDBAppDependencies *deps = self.dependencies;
  MDBMovieCellModel *movie = [self cellModel];

  [self assertReleased:^UIViewController * {
    return [[MDBHomeViewController alloc] initWithViewModel:[[MDBHomeViewModel alloc] initWithServices:deps.movieService
                                                                                             imageURLs:deps.imageURLs
                                                                                           preferences:deps.preferences.current]];
  }
                  name:@"Home"];
  [self assertReleased:^UIViewController * {
    MDBExploreViewModel *viewModel = [[MDBExploreViewModel alloc] initWithServices:deps.movieService
                                                                         imageURLs:deps.imageURLs
                                                                       preferences:deps.preferences.current
                                                                  debounceInterval:0.01];
    return [[MDBExploreViewController alloc] initWithViewModel:viewModel];
  }
                  name:@"Explore"];
  [self assertReleased:^UIViewController * {
    return [[MDBFavoritesViewController alloc]
        initWithViewModel:[[MDBFavoritesViewModel alloc] initWithFavoritesStore:deps.favoritesStore imageURLs:deps.imageURLs]];
  }
                  name:@"Favorites"];
  [self assertReleased:^UIViewController * {
    return [[MDBMenuViewController alloc] initWithViewModel:[[MDBMenuViewModel alloc] initWithGenreProvider:deps.movieService
                                                                                                preferences:deps.preferences
                                                                                             favoritesStore:deps.favoritesStore]];
  }
                  name:@"Menu"];
  [self assertReleased:^UIViewController * {
    MDBMovieDetailViewModel *viewModel = [[MDBMovieDetailViewModel alloc] initWithMovieID:movie.movieID
                                                                                seedMovie:movie.movie
                                                                                 services:deps.movieService
                                                                           favoritesStore:deps.favoritesStore
                                                                                imageURLs:deps.imageURLs];
    return [[MDBMovieDetailViewController alloc] initWithViewModel:viewModel];
  }
                  name:@"Movie Detail"];
  [self assertReleased:^UIViewController * {
    return [[MDBPersonViewController alloc] initWithViewModel:[[MDBPersonViewModel alloc] initWithPersonID:1
                                                                                                      name:@"Someone"
                                                                                                  services:deps.movieService
                                                                                                 imageURLs:deps.imageURLs]];
  }
                  name:@"Person"];
  [self assertReleased:^UIViewController * {
    return [[MDBMovieListViewController alloc] initWithViewModel:[[MDBMovieListViewModel alloc] initWithListKind:MDBMovieListKindPopular
                                                                                                        services:deps.movieService
                                                                                                       imageURLs:deps.imageURLs]];
  }
                  name:@"Movie List"];
}

@end
