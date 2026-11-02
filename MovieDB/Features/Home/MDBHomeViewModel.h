//
//  MDBHomeViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBObservable<ObjectType>;
@class MDBPreferenceSnapshot;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBHomeSection : NSObject

@property (nonatomic, readonly) MDBMovieListKind kind;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *items;

- (instancetype)initWithKind:(MDBMovieListKind)kind items:(NSArray<MDBMovieCellModel *> *)items NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBHomeContent : NSObject

@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *carouselItems;
@property (nonatomic, copy, readonly) NSArray<MDBHomeSection *> *sections;

- (instancetype)initWithCarouselItems:(NSArray<MDBMovieCellModel *> *)carouselItems
                             sections:(NSArray<MDBHomeSection *> *)sections NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

typedef id<MDBMovieListProviding, MDBGenreProviding> MDBHomeServices;

@interface MDBHomeViewModel : NSObject

@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBHomeContent *> *> *state;

/// Reloads by itself when the region or language changes.
- (instancetype)initWithServices:(MDBHomeServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs
                     preferences:(MDBObservable<MDBPreferenceSnapshot *> *)preferences NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Loads once. Later calls do nothing unless the last load failed.
- (void)loadIfNeeded;
/// Always starts over, used by pull to refresh and Retry.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
