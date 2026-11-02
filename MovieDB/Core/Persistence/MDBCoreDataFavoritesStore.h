//
//  MDBCoreDataFavoritesStore.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"

@class MDBCoreDataStack;

NS_ASSUME_NONNULL_BEGIN

@interface MDBCoreDataFavoritesStore : NSObject <MDBFavoritesStore>

- (instancetype)initWithStack:(MDBCoreDataStack *)stack
           notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
