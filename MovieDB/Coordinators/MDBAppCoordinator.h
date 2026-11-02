//
//  MDBAppCoordinator.h
//  MovieDB
//

#import <UIKit/UIKit.h>
#import "MDBCoordinator.h"

@class MDBAppDependencies;

NS_ASSUME_NONNULL_BEGIN

/// Root of the coordinator tree. Builds the tab bar and owns the debug menu in Debug builds.
@interface MDBAppCoordinator : MDBBaseCoordinator

@property (nonatomic, readonly) MDBAppDependencies *dependencies;
@property (nonatomic, readonly) UITabBarController *tabBarController;

- (instancetype)initWithWindow:(UIWindow *)window dependencies:(MDBAppDependencies *)dependencies NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)presentDebugMenu;

@end

NS_ASSUME_NONNULL_END
