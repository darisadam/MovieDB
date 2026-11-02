//
//  MDBMovieFlowCoordinator.m
//  MovieDB
//

#import "MDBMovieFlowCoordinator.h"
#import "MDBAboutViewController.h"
#import "MDBAppDependencies.h"
#import "MDBCastCell.h"
#import "MDBGenre.h"
#import "MDBLog.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetailViewController.h"
#import "MDBMovieDetailViewModel.h"
#import "MDBMovieListViewController.h"
#import "MDBMovieListViewModel.h"
#import "MDBPersonViewController.h"
#import "MDBPersonViewModel.h"
#import "MDBTheme.h"
#import "MDBTrailerViewController.h"
#import <SafariServices/SafariServices.h>

@interface MDBMovieFlowCoordinator () <MDBMovieDetailViewControllerDelegate,
                                       MDBPersonViewControllerDelegate,
                                       MDBMovieListViewControllerDelegate,
                                       MDBTrailerViewControllerDelegate,
                                       MDBAboutViewControllerDelegate>
@end

@implementation MDBMovieFlowCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                dependencies:(MDBAppDependencies *)dependencies {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _dependencies = dependencies;
    }
    return self;
}

#pragma mark - Routes

- (void)showMovie:(MDBMovieCellModel *)movie {
    MDBLogInfo(MDBLogCategoryCoordinator, @"Show movie %ld %@", (long)movie.movieID, movie.title);
    MDBAppDependencies *deps = self.dependencies;
    MDBMovieDetailViewModel *viewModel = [[MDBMovieDetailViewModel alloc] initWithMovieID:movie.movieID
                                                                                seedMovie:movie.movie
                                                                             movieService:deps.movieService
                                                                           favoritesStore:deps.favoritesStore
                                                                                imageURLs:deps.imageURLs
                                                                       notificationCenter:deps.notificationCenter];
    MDBMovieDetailViewController *controller = [[MDBMovieDetailViewController alloc] initWithViewModel:viewModel];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showMovieList:(MDBMovieListKind)kind {
    MDBLogInfo(MDBLogCategoryCoordinator, @"Show list %@", MDBMovieListKindTitle(kind));
    MDBMovieListViewModel *viewModel = [[MDBMovieListViewModel alloc] initWithListKind:kind
                                                                          movieService:self.dependencies.movieService
                                                                             imageURLs:self.dependencies.imageURLs];
    [self pushListWithViewModel:viewModel];
}

- (void)showGenre:(MDBGenre *)genre {
    MDBLogInfo(MDBLogCategoryCoordinator, @"Show genre %@", genre.name);
    MDBMovieListViewModel *viewModel = [[MDBMovieListViewModel alloc] initWithGenre:genre
                                                                       movieService:self.dependencies.movieService
                                                                          imageURLs:self.dependencies.imageURLs];
    [self pushListWithViewModel:viewModel];
}

- (void)pushListWithViewModel:(MDBMovieListViewModel *)viewModel {
    MDBMovieListViewController *controller = [[MDBMovieListViewController alloc] initWithViewModel:viewModel];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showPersonWithID:(NSInteger)personID name:(NSString *)name {
    MDBLogInfo(MDBLogCategoryCoordinator, @"Show person %ld %@", (long)personID, name);
    MDBPersonViewModel *viewModel = [[MDBPersonViewModel alloc] initWithPersonID:personID
                                                                            name:name
                                                                    movieService:self.dependencies.movieService
                                                                       imageURLs:self.dependencies.imageURLs];
    MDBPersonViewController *controller = [[MDBPersonViewController alloc] initWithViewModel:viewModel];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showAbout {
    MDBAboutViewController *controller = [[MDBAboutViewController alloc] init];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showTrailers:(NSArray<MDBVideo *> *)videos movieTitle:(NSString *)movieTitle {
    MDBTrailerViewController *controller = [[MDBTrailerViewController alloc] initWithVideos:videos movieTitle:movieTitle];
    controller.delegate = self;
    controller.modalPresentationStyle = UIModalPresentationPageSheet;
    UISheetPresentationController *sheet = controller.sheetPresentationController;
    sheet.detents = @[[UISheetPresentationControllerDetent mediumDetent], [UISheetPresentationControllerDetent largeDetent]];
    if (@available(iOS 16.0, *)) {
        // Tall enough for the player, the title and the first couple of videos.
        UISheetPresentationControllerDetent *player = [UISheetPresentationControllerDetent customDetentWithIdentifier:@"player"
                                                                                                             resolver:^CGFloat(id<UISheetPresentationControllerDetentResolutionContext> context) {
            return MIN(context.maximumDetentValue, 560);
        }];
        sheet.detents = @[player, [UISheetPresentationControllerDetent largeDetent]];
        sheet.selectedDetentIdentifier = @"player";
    }
    sheet.prefersGrabberVisible = YES;
    sheet.preferredCornerRadius = 20;
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)openURL:(NSURL *)url {
    MDBLogInfo(MDBLogCategoryCoordinator, @"Open %@", url.absoluteString);
    BOOL isYouTube = [url.host containsString:@"youtube.com"] || [url.host containsString:@"youtu.be"];
    UIViewController *presenter = self.navigationController.presentedViewController ?: self.navigationController;
    if (isYouTube) {
        // Universal link: opens the YouTube app if installed, otherwise Safari.
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        return;
    }
    if (![url.scheme isEqualToString:@"https"] && ![url.scheme isEqualToString:@"http"]) {
        MDBLogError(MDBLogCategoryCoordinator, @"Refusing to open non web URL %@", url);
        return;
    }
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:url];
    safari.preferredControlTintColor = UIColor.mdb_accent;
    safari.preferredBarTintColor = UIColor.mdb_surface;
    [presenter presentViewController:safari animated:YES completion:nil];
}

#pragma mark - MDBMovieDetailViewControllerDelegate

- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller didSelectCastMember:(MDBCastCellModel *)castMember {
    [self showPersonWithID:castMember.personID name:castMember.name];
}

- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
    [self showMovie:movie];
}

- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller
               didRequestTrailers:(NSArray<MDBVideo *> *)videos
                       movieTitle:(NSString *)movieTitle {
    [self showTrailers:videos movieTitle:movieTitle];
}

#pragma mark - MDBPersonViewControllerDelegate

- (void)personViewController:(MDBPersonViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
    [self showMovie:movie];
}

#pragma mark - MDBMovieListViewControllerDelegate

- (void)movieListViewController:(MDBMovieListViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie {
    [self showMovie:movie];
}

#pragma mark - MDBTrailerViewControllerDelegate

- (void)trailerViewController:(MDBTrailerViewController *)controller openExternalURL:(NSURL *)url {
    [self openURL:url];
}

- (void)trailerViewControllerDidClose:(MDBTrailerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MDBAboutViewControllerDelegate

- (void)aboutViewController:(MDBAboutViewController *)controller openURL:(NSURL *)url {
    [self openURL:url];
}

@end
