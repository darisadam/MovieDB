//
//  MDBMovieListViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMovieListViewModel;
@class MDBMovieListViewController;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBMovieListViewControllerDelegate <NSObject>
- (void)movieListViewController:(MDBMovieListViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
@end

@interface MDBMovieListViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBMovieListViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBMovieListViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
