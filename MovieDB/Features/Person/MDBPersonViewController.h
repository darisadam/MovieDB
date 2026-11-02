//
//  MDBPersonViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBPersonViewModel;
@class MDBPersonViewController;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBPersonViewControllerDelegate <NSObject>
- (void)personViewController:(MDBPersonViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
@end

@interface MDBPersonViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBPersonViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBPersonViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
