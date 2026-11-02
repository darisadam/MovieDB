//
//  MDBFavoritesViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBFavoritesViewModel;
@class MDBFavoritesViewController;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBFavoritesViewControllerDelegate <NSObject>
- (void)favoritesViewController:(MDBFavoritesViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
- (void)favoritesViewControllerDidRequestExplore:(MDBFavoritesViewController *)controller;
@end

@interface MDBFavoritesViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBFavoritesViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBFavoritesViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
