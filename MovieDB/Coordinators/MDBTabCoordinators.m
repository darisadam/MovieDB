//
//  MDBTabCoordinators.m
//  MovieDB
//

#import "MDBTabCoordinators.h"
#import "MDBAppDependencies.h"
#import "MDBExploreViewController.h"
#import "MDBExploreViewModel.h"
#import "MDBFavoritesViewController.h"
#import "MDBFavoritesViewModel.h"
#import "MDBHomeViewController.h"
#import "MDBHomeViewModel.h"
#import "MDBMenuViewController.h"
#import "MDBMenuViewModel.h"
#import "MDBPreferences.h"

#pragma mark - Home

@interface MDBHomeCoordinator () <MDBHomeViewControllerDelegate>
@end

@implementation MDBHomeCoordinator

- (void)start {
  [super start];
  MDBAppDependencies *deps = self.dependencies;
  MDBHomeViewModel *viewModel = [[MDBHomeViewModel alloc] initWithServices:deps.movieService imageURLs:deps.imageURLs
                                                               preferences:deps.preferences.current];
  MDBHomeViewController *controller = [[MDBHomeViewController alloc] initWithViewModel:viewModel];
  controller.delegate = self;
  [self.navigationController setViewControllers:@[ controller ] animated:NO];
}

- (void)homeViewController:(MDBHomeViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
  [self showMovie:movie];
}

- (void)homeViewController:(MDBHomeViewController *)controller didSelectSeeAllForKind:(MDBMovieListKind)kind {
  [self showMovieList:kind];
}

@end

#pragma mark - Explore

@interface MDBExploreCoordinator () <MDBExploreViewControllerDelegate>
@property (nonatomic, weak) MDBExploreViewController *rootController;
@end

@implementation MDBExploreCoordinator

- (void)start {
  [super start];
  MDBAppDependencies *deps = self.dependencies;
  MDBExploreViewModel *viewModel = [[MDBExploreViewModel alloc] initWithServices:deps.movieService imageURLs:deps.imageURLs
                                                                     preferences:deps.preferences.current
                                                                debounceInterval:0.4];
  MDBExploreViewController *controller = [[MDBExploreViewController alloc] initWithViewModel:viewModel];
  controller.delegate = self;
  self.rootController = controller;
  [self.navigationController setViewControllers:@[ controller ] animated:NO];
}

- (void)focusSearch {
  [self.navigationController popToRootViewControllerAnimated:NO];
  [self.rootController focusSearch];
}

- (void)exploreViewController:(MDBExploreViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
  [self showMovie:movie];
}

- (void)exploreViewController:(MDBExploreViewController *)controller didSelectGenre:(MDBGenre *)genre {
  [self showGenre:genre];
}

@end

#pragma mark - Favorites

@interface MDBFavoritesCoordinator () <MDBFavoritesViewControllerDelegate>
@end

@implementation MDBFavoritesCoordinator

- (void)start {
  [super start];
  MDBAppDependencies *deps = self.dependencies;
  MDBFavoritesViewModel *viewModel = [[MDBFavoritesViewModel alloc] initWithFavoritesStore:deps.favoritesStore
                                                                                 imageURLs:deps.imageURLs];
  MDBFavoritesViewController *controller = [[MDBFavoritesViewController alloc] initWithViewModel:viewModel];
  controller.delegate = self;
  [self.navigationController setViewControllers:@[ controller ] animated:NO];
}

- (void)favoritesViewController:(MDBFavoritesViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
  [self showMovie:movie];
}

- (void)favoritesViewControllerDidRequestExplore:(MDBFavoritesViewController *)controller {
  if (self.onRequestExplore) {
    self.onRequestExplore();
  }
}

@end

#pragma mark - Menu

@interface MDBMenuCoordinator () <MDBMenuViewControllerDelegate>
@end

@implementation MDBMenuCoordinator

- (void)start {
  [super start];
  MDBAppDependencies *deps = self.dependencies;
  MDBMenuViewModel *viewModel = [[MDBMenuViewModel alloc] initWithGenreProvider:deps.movieService preferences:deps.preferences
                                                                 favoritesStore:deps.favoritesStore];
  MDBMenuViewController *controller = [[MDBMenuViewController alloc] initWithViewModel:viewModel];
  controller.delegate = self;
  [self.navigationController setViewControllers:@[ controller ] animated:NO];
}

- (void)menuViewController:(MDBMenuViewController *)controller didSelectGenre:(MDBGenre *)genre {
  [self showGenre:genre];
}

- (void)menuViewControllerDidSelectAbout:(MDBMenuViewController *)controller {
  [self showAbout];
}

@end
