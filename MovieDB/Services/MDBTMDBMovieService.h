//
//  MDBTMDBMovieService.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBAPIClient;
@class MDBPreferences;

NS_ASSUME_NONNULL_BEGIN

@interface MDBTMDBMovieService : NSObject <MDBMovieService>

- (instancetype)initWithClient:(MDBAPIClient *)client preferences:(MDBPreferences *)preferences NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
