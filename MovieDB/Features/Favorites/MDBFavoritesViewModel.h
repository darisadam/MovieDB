//
//  MDBFavoritesViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"
#import "MDBLoadState.h"

@class MDBMovieCellModel;
@class MDBImageURLBuilder;

NS_ASSUME_NONNULL_BEGIN

@interface MDBFavoritesViewModel : NSObject

@property (nonatomic, readonly) MDBLoadState state;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithFavoritesStore:(id<MDBFavoritesStore>)favoritesStore
                             imageURLs:(MDBImageURLBuilder *)imageURLs
                    notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)reload;
- (void)removeItemAtIndex:(NSUInteger)index;
/// "4 movies · saved on this device"
- (NSString *)summaryText;

@end

NS_ASSUME_NONNULL_END
