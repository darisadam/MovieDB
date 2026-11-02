//
//  MDBHomeViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>
#import "MDBMovieService.h"

@class MDBHomeViewModel;
@class MDBHomeViewController;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBHomeViewControllerDelegate <NSObject>
- (void)homeViewController:(MDBHomeViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
- (void)homeViewController:(MDBHomeViewController *)controller didSelectSeeAllForKind:(MDBMovieListKind)kind;
@end

@interface MDBHomeViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBHomeViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBHomeViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
