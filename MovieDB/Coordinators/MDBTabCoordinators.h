//
//  MDBTabCoordinators.h
//  MovieDB
//
//  One coordinator per tab. Each sets up its root screen and reuses the movie flow from the base class.
//

#import "MDBMovieFlowCoordinator.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDBHomeCoordinator : MDBMovieFlowCoordinator
@end

@interface MDBExploreCoordinator : MDBMovieFlowCoordinator
- (void)focusSearch;
@end

@interface MDBFavoritesCoordinator : MDBMovieFlowCoordinator
/// Fired by the empty state's "Explore Movies" button.
@property (nonatomic, copy, nullable) void (^onRequestExplore)(void);
@end

@interface MDBMenuCoordinator : MDBMovieFlowCoordinator
@end

NS_ASSUME_NONNULL_END
