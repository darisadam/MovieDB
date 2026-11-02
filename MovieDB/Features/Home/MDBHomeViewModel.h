//
//  MDBHomeViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBMovieCellModel;
@class MDBImageURLBuilder;

NS_ASSUME_NONNULL_BEGIN

@interface MDBHomeSection : NSObject

@property (nonatomic, readonly) MDBMovieListKind kind;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *items;

- (instancetype)initWithKind:(MDBMovieListKind)kind items:(NSArray<MDBMovieCellModel *> *)items NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBHomeViewModel : NSObject

@property (nonatomic, readonly) MDBLoadState state;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *carouselItems;
@property (nonatomic, copy, readonly) NSArray<MDBHomeSection *> *sections;

/// Called on the main queue whenever anything above changes.
@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithMovieService:(id<MDBMovieService>)movieService
                           imageURLs:(MDBImageURLBuilder *)imageURLs
                  notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Loads once. Later calls do nothing unless the last load failed.
- (void)loadIfNeeded;
/// Always starts over, used by pull to refresh and Retry.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
