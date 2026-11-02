//
//  MDBTrailerViewController.h
//  MovieDB
//
//  Presented as a sheet over the detail screen. Plays YouTube videos in an embedded player.
//

#import <UIKit/UIKit.h>

@class MDBVideo;
@class MDBTrailerViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBTrailerViewControllerDelegate <NSObject>
- (void)trailerViewController:(MDBTrailerViewController *)controller openExternalURL:(NSURL *)url;
- (void)trailerViewControllerDidClose:(MDBTrailerViewController *)controller;
@end

@interface MDBTrailerViewController : UIViewController

@property (nonatomic, weak, nullable) id<MDBTrailerViewControllerDelegate> delegate;

- (instancetype)initWithVideos:(NSArray<MDBVideo *> *)videos movieTitle:(NSString *)movieTitle NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// The YouTube embed page. Public so tests can check the escaping.
+ (NSString *)embedHTMLForVideoKey:(NSString *)videoKey;

@end

NS_ASSUME_NONNULL_END
