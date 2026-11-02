//
//  MDBDebugMenuViewController.h
//  MovieDB
//
//  Shake the device (or press Ctrl+Cmd+Z in the simulator) in a Debug build to open this.
//

#import <UIKit/UIKit.h>

#if DEBUG

@class MDBAppDependencies;

NS_ASSUME_NONNULL_BEGIN

@interface MDBDebugMenuViewController : UITableViewController

- (instancetype)initWithDependencies:(MDBAppDependencies *)dependencies
                     coordinatorTree:(NSString *)coordinatorTree NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
