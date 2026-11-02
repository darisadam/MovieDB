//
//  MDBAppCoordinator.m
//  MovieDB
//

#import "MDBAppCoordinator.h"
#import "MDBAppDependencies.h"
#import "MDBLog.h"
#import "MDBTabCoordinators.h"
#import "MDBTheme.h"
#import "MDBWindow.h"
#if DEBUG
#import "MDBDebugMenuViewController.h"
#endif

typedef NS_ENUM(NSUInteger, MDBTab) {
    MDBTabHome = 0,
    MDBTabExplore,
    MDBTabFavorites,
    MDBTabMenu,
};

@interface MDBAppCoordinator ()
@property (nonatomic, weak, readonly) UIWindow *window;
@property (nonatomic, readwrite) UITabBarController *tabBarController;
@property (nonatomic, weak) MDBExploreCoordinator *exploreCoordinator;
@property (nonatomic) id shakeObserver;
@end

@implementation MDBAppCoordinator

- (instancetype)initWithWindow:(UIWindow *)window dependencies:(MDBAppDependencies *)dependencies {
    self = [super init];
    if (self) {
        _window = window;
        _dependencies = dependencies;
        _tabBarController = [[UITabBarController alloc] init];
    }
    return self;
}

- (void)dealloc {
    if (_shakeObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_shakeObserver];
    }
}

- (void)start {
    [super start];

    MDBHomeCoordinator *home = [[MDBHomeCoordinator alloc] initWithNavigationController:[self navigationControllerWithLargeTitles:NO]
                                                                           dependencies:self.dependencies];
    MDBExploreCoordinator *explore = [[MDBExploreCoordinator alloc] initWithNavigationController:[self navigationControllerWithLargeTitles:YES]
                                                                                    dependencies:self.dependencies];
    MDBFavoritesCoordinator *favorites = [[MDBFavoritesCoordinator alloc] initWithNavigationController:[self navigationControllerWithLargeTitles:YES]
                                                                                          dependencies:self.dependencies];
    MDBMenuCoordinator *menu = [[MDBMenuCoordinator alloc] initWithNavigationController:[self navigationControllerWithLargeTitles:YES]
                                                                           dependencies:self.dependencies];
    self.exploreCoordinator = explore;

    __weak typeof(self) weakSelf = self;
    favorites.onRequestExplore = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.tabBarController.selectedIndex = MDBTabExplore;
        [strongSelf.exploreCoordinator focusSearch];
    };

    NSArray<MDBMovieFlowCoordinator *> *tabs = @[home, explore, favorites, menu];
    NSArray<NSString *> *titles = @[@"Home", @"Explore", @"Favorites", @"Menu"];
    NSArray<NSString *> *symbols = @[@"house", @"magnifyingglass", @"heart", @"square.grid.2x2"];
    NSArray<NSString *> *selectedSymbols = @[@"house.fill", @"magnifyingglass", @"heart.fill", @"square.grid.2x2.fill"];
    NSMutableArray<UINavigationController *> *controllers = [NSMutableArray arrayWithCapacity:tabs.count];

    [tabs enumerateObjectsUsingBlock:^(MDBMovieFlowCoordinator *coordinator, NSUInteger index, BOOL *stop) {
        [self addChildCoordinator:coordinator];
        [coordinator start];
        UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:nil
                                                           image:[UIImage systemImageNamed:symbols[index]]
                                                   selectedImage:[UIImage systemImageNamed:selectedSymbols[index]]];
        // The design shows icons only, so center them and keep the title for VoiceOver.
        item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
        item.accessibilityLabel = titles[index];
        coordinator.navigationController.tabBarItem = item;
        [controllers addObject:coordinator.navigationController];
    }];

    self.tabBarController.viewControllers = controllers;
    UIWindow *window = self.window;
    window.rootViewController = self.tabBarController;
    [window makeKeyAndVisible];

#if DEBUG
    self.shakeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MDBDebugShakeNotification
                                                                           object:nil
                                                                            queue:[NSOperationQueue mainQueue]
                                                                       usingBlock:^(NSNotification *note) {
        [weakSelf presentDebugMenu];
    }];
#endif
    MDBLogInfo(MDBLogCategoryCoordinator, @"App coordinator tree:\n%@", [self treeDescription]);
}

- (UINavigationController *)navigationControllerWithLargeTitles:(BOOL)largeTitles {
    UINavigationController *navigation = [[UINavigationController alloc] init];
    navigation.navigationBar.prefersLargeTitles = largeTitles;
    navigation.view.backgroundColor = UIColor.mdb_background;
    return navigation;
}

- (void)presentDebugMenu {
#if DEBUG
    UIViewController *top = self.tabBarController;
    while (top.presentedViewController) {
        top = top.presentedViewController;
    }
    if ([top isKindOfClass:[UINavigationController class]] &&
        [((UINavigationController *)top).viewControllers.firstObject isKindOfClass:[MDBDebugMenuViewController class]]) {
        return;
    }
    MDBDebugMenuViewController *menu = [[MDBDebugMenuViewController alloc] initWithDependencies:self.dependencies
                                                                                 coordinatorTree:[self treeDescription]];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:menu];
    [top presentViewController:navigation animated:YES completion:nil];
#endif
}

@end
