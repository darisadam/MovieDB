//
//  MDBAppDelegate.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBAppDependencies;

NS_ASSUME_NONNULL_BEGIN

@interface MDBAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, readonly) MDBAppDependencies *dependencies;

@end

NS_ASSUME_NONNULL_END
