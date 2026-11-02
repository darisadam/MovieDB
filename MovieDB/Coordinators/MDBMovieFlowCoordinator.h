//
//  MDBMovieFlowCoordinator.h
//  MovieDB
//
//  Base class for the four tab coordinators. Holds the screens every tab can push:
//  movie detail, person, lists, genre results, trailers and about.
//

#import <UIKit/UIKit.h>
#import "MDBCoordinator.h"
#import "MDBMovieService.h"

@class MDBAppDependencies;
@class MDBGenre;
@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieFlowCoordinator : MDBBaseCoordinator

@property (nonatomic, readonly) UINavigationController *navigationController;
@property (nonatomic, readonly) MDBAppDependencies *dependencies;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                dependencies:(MDBAppDependencies *)dependencies NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)showMovie:(MDBMovieCellModel *)movie;
- (void)showMovieList:(MDBMovieListKind)kind;
- (void)showGenre:(MDBGenre *)genre;
- (void)showPersonWithID:(NSInteger)personID name:(NSString *)name;
- (void)showAbout;
/// Web pages open in an in-app Safari sheet, YouTube links go to the YouTube app when it is installed.
- (void)openURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
