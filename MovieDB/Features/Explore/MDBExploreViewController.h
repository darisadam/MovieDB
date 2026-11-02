//
//  MDBExploreViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBExploreViewModel;
@class MDBExploreViewController;
@class MDBMovieCellModel;
@class MDBGenre;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBExploreViewControllerDelegate <NSObject>
- (void)exploreViewController:(MDBExploreViewController *)controller didSelectMovie:(MDBMovieCellModel *)movie;
- (void)exploreViewController:(MDBExploreViewController *)controller didSelectGenre:(MDBGenre *)genre;
@end

@interface MDBExploreViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBExploreViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(MDBExploreViewModel *)viewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Puts the cursor in the search field. Used by the empty Favorites screen.
- (void)focusSearch;

@end

NS_ASSUME_NONNULL_END
