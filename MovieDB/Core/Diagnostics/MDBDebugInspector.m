//
//  MDBDebugInspector.m
//  MovieDB
//

#import "MDBDebugInspector.h"

#if DEBUG

#import "MDBAPIClient.h"
#import "MDBAppCoordinator.h"
#import "MDBAppDelegate.h"
#import "MDBAppDependencies.h"
#import "MDBLog.h"
#import "MDBNetworkActivityLog.h"
#import "MDBPreferences.h"
#import "MDBSceneDelegate.h"
#import "MDBTMDBConfiguration.h"
#import <UIKit/UIKit.h>

@implementation MDBDebugInspector

+ (nullable MDBAppDependencies *)dependencies {
    id delegate = UIApplication.sharedApplication.delegate;
    return [delegate isKindOfClass:[MDBAppDelegate class]] ? ((MDBAppDelegate *)delegate).dependencies : nil;
}

+ (nullable UIWindowScene *)activeScene {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (NSString *)viewControllerTree {
    UIWindowScene *scene = [self activeScene];
    UIWindow *window = scene.keyWindow ?: scene.windows.firstObject;
    if (!window.rootViewController) {
        return @"No window yet.";
    }
    NSMutableString *output = [NSMutableString string];
    [self appendController:window.rootViewController to:output depth:0];
    return output;
}

+ (void)appendController:(UIViewController *)controller to:(NSMutableString *)output depth:(NSUInteger)depth {
    NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
    BOOL visible = controller.isViewLoaded && controller.view.window != nil;
    [output appendFormat:@"%@%@ %p%@%@\n", indent, NSStringFromClass([controller class]), controller,
     controller.title.length > 0 ? [NSString stringWithFormat:@" \"%@\"", controller.title] : @"",
     visible ? @"  <- on screen" : @""];
    for (UIViewController *child in controller.childViewControllers) {
        [self appendController:child to:output depth:depth + 1];
    }
    if (controller.presentedViewController && controller.presentedViewController.presentingViewController == controller) {
        [output appendFormat:@"%@  presents:\n", indent];
        [self appendController:controller.presentedViewController to:output depth:depth + 2];
    }
}

+ (NSString *)coordinatorTree {
    id delegate = [self activeScene].delegate;
    if (![delegate isKindOfClass:[MDBSceneDelegate class]]) {
        return @"No scene delegate.";
    }
    MDBAppCoordinator *coordinator = ((MDBSceneDelegate *)delegate).appCoordinator;
    return coordinator ? [coordinator treeDescription] : @"App coordinator not started.";
}

+ (NSString *)recentRequests {
    NSArray<MDBNetworkActivityEntry *> *entries = [[self dependencies].networkLog recentEntries];
    if (entries.count == 0) {
        return @"No requests yet.";
    }
    NSMutableString *output = [NSMutableString string];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    for (MDBNetworkActivityEntry *entry in entries) {
        [output appendFormat:@"%@  %@\n", [formatter stringFromDate:entry.date], entry.summary];
    }
    return output;
}

+ (NSString *)lastRequestAsCURL {
    MDBNetworkActivityEntry *entry = [[self dependencies].networkLog recentEntries].firstObject;
    return entry ? entry.cURLCommand : @"No requests yet.";
}

+ (NSString *)favorites {
    NSArray<MDBFavoriteMovie *> *favorites = [[self dependencies].favoritesStore allFavorites];
    if (favorites.count == 0) {
        return @"No favorites saved.";
    }
    NSMutableString *output = [NSMutableString stringWithFormat:@"%lu favorites\n", (unsigned long)favorites.count];
    for (MDBFavoriteMovie *favorite in favorites) {
        [output appendFormat:@"  %@\n", favorite];
    }
    return output;
}

+ (NSString *)recentLogs {
    NSArray<NSString *> *lines = MDBLogRecentLines();
    return lines.count > 0 ? [lines componentsJoinedByString:@"\n"] : @"No log lines yet.";
}

+ (NSString *)configuration {
    MDBAppDependencies *deps = [self dependencies];
    return [NSString stringWithFormat:@"%@\nregion %@, language %@, offline mode %@, log level %ld",
            deps.configuration, deps.preferences.regionCode, deps.preferences.languageCode,
            deps.apiClient.simulatesOffline ? @"on" : @"off", (long)MDBLogMinimumLevel()];
}

+ (void)setOfflineMode:(BOOL)offline {
    [self dependencies].apiClient.simulatesOffline = offline;
    MDBLogInfo(MDBLogCategoryApp, @"Offline mode %@ from the debugger", offline ? @"on" : @"off");
}

+ (void)setLogLevel:(NSInteger)level {
    MDBLogSetMinimumLevel((MDBLogLevel)level);
    MDBLogInfo(MDBLogCategoryApp, @"Log level set to %ld", (long)level);
}

@end

#endif
