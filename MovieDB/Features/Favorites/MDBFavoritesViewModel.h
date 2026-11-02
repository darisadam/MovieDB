//
//  MDBFavoritesViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"

@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBObservable<ObjectType>;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBFavoritesViewModel : NSObject

/// Loaded with the saved movies, or empty. Follows the store, so changes from other screens show up here.
@property (nonatomic, readonly) MDBObservable<MDBScreenState<NSArray<MDBMovieCellModel *> *> *> *state;

- (instancetype)initWithFavoritesStore:(id<MDBFavoritesStore>)favoritesStore
                             imageURLs:(MDBImageURLBuilder *)imageURLs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)removeMovieWithID:(NSInteger)movieID;
/// "4 movies · saved on this device"
+ (NSString *)summaryForCount:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
