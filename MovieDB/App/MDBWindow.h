//
//  MDBWindow.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Posted when the device is shaken in a Debug build. The app coordinator opens the debug menu.
FOUNDATION_EXPORT NSNotificationName const MDBDebugShakeNotification;

@interface MDBWindow : UIWindow
@end

NS_ASSUME_NONNULL_END
