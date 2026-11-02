//
//  MDBCoreDataFavoritesStore.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBFavoritesStore.h"

@class MDBCoreDataStack;

NS_ASSUME_NONNULL_BEGIN

@interface MDBCoreDataFavoritesStore : NSObject <MDBFavoritesStore>

/// Reads the saved favorites right away, so create it on the main thread.
- (instancetype)initWithStack:(MDBCoreDataStack *)stack NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
