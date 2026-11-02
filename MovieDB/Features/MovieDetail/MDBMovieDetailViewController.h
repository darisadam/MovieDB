//
//  MDBMovieDetailViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMovieDetailViewModel;
@class MDBMovieDetailViewController;
@class MDBCastCellModel;
@class MDBMovieCellModel;
@class MDBVideo;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBMovieDetailViewControllerDelegate <NSObject>
- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller didSelectCastMember:(MDBCastCellModel *)castMember;
- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
- (void)movieDetailViewController:(MDBMovieDetailViewController *)controller
               didRequestTrailers:(NSArray<MDBVideo *> *)videos
                       movieTitle:(NSString *)movieTitle;
@end

@interface MDBMovieDetailViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBMovieDetailViewControllerDelegate> delegate;
@property (nonatomic, readonly) MDBMovieDetailViewModel *viewModel;

- (instancetype)initWithViewModel:(MDBMovieDetailViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
