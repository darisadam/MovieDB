//
//  MDBSceneDelegate.m
//  MovieDB
//

#import "MDBSceneDelegate.h"
#import "MDBAppCoordinator.h"
#import "MDBAppDelegate.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBTheme.h"
#import "MDBWindow.h"

@interface MDBSceneDelegate ()
@property (nonatomic, readwrite, nullable) MDBAppCoordinator *appCoordinator;
@end

@implementation MDBSceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
  if (![scene isKindOfClass:[UIWindowScene class]]) {
    return;
  }
  UIWindowScene *windowScene = (UIWindowScene *)scene;
  MDBWindow *window = [[MDBWindow alloc] initWithWindowScene:windowScene];
  window.backgroundColor = UIColor.mdb_background;
  window.tintColor = UIColor.mdb_accent;
  window.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
  self.window = window;

  if (MDBIsRunningUnitTests()) {
    // Tests don't need the real UI or its network calls.
    window.rootViewController = [[UIViewController alloc] init];
    [window makeKeyAndVisible];
    return;
  }

  MDBAppDelegate *appDelegate = (MDBAppDelegate *)UIApplication.sharedApplication.delegate;
  self.appCoordinator = [[MDBAppCoordinator alloc] initWithWindow:window dependencies:appDelegate.dependencies];
  [self.appCoordinator start];
  MDBLogInfo(MDBLogCategoryCoordinator, @"Scene connected");
}

- (void)sceneDidDisconnect:(UIScene *)scene {
  MDBLogInfo(MDBLogCategoryCoordinator, @"Scene disconnected");
  self.appCoordinator = nil;
}

@end
