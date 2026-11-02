//
//  MDBAppDelegate.m
//  MovieDB
//

#import "MDBAppDelegate.h"
#import "MDBAppDependencies.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMetricsSubscriber.h"
#import "MDBTheme.h"

@interface MDBAppDelegate ()
@property (nonatomic, readwrite) MDBAppDependencies *dependencies;
@end

@implementation MDBAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
  NSDictionary *info = [NSBundle mainBundle].infoDictionary;
  MDBLogInfo(MDBLogCategoryApp, @"Launching MovieDB %@ (%@) on iOS %@", info[@"CFBundleShortVersionString"],
             info[@"CFBundleVersion"], UIDevice.currentDevice.systemVersion);

  self.dependencies = [MDBAppDependencies liveDependencies];
  [MDBTheme applyGlobalAppearance];
  if (!MDBIsRunningUnitTests()) {
    [self.dependencies.metrics start];
  }
  return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  MDBLogError(MDBLogCategoryApp, @"Memory warning received");
}

@end
