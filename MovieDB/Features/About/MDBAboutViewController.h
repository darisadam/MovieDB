//
//  MDBAboutViewController.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBAboutViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBAboutViewControllerDelegate <NSObject>
- (void)aboutViewController:(MDBAboutViewController *)controller openURL:(NSURL *)url;
@end

/// App version, the TMDB attribution their terms ask for, and a few links.
@interface MDBAboutViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBAboutViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
