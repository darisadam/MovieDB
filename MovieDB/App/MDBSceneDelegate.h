//
//  MDBSceneDelegate.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBAppCoordinator;

NS_ASSUME_NONNULL_BEGIN

@interface MDBSceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (nonatomic, nullable) UIWindow *window;
@property (nonatomic, readonly, nullable) MDBAppCoordinator *appCoordinator;

@end

NS_ASSUME_NONNULL_END
