//
//  MDBMenuViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMenuViewModel;
@class MDBMenuViewController;
@class MDBGenre;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBMenuViewControllerDelegate <NSObject>
- (void)menuViewController:(MDBMenuViewController *)controller didSelectGenre:(MDBGenre *)genre;
- (void)menuViewControllerDidSelectAbout:(MDBMenuViewController *)controller;
@end

@interface MDBMenuViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBMenuViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBMenuViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
