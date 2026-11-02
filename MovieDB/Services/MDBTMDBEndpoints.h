//
//  MDBTMDBEndpoints.h
//  MovieDB
//
//  Every TMDB path and query the app uses, in one place.
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBEndpoint;

NS_ASSUME_NONNULL_BEGIN

@interface MDBTMDBEndpoints : NSObject

/// language is an "en-US" style code, region a two letter country code.
- (instancetype)initWithLanguage:(NSString *)language region:(NSString *)region NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (MDBEndpoint *)movieList:(MDBMovieListKind)kind page:(NSInteger)page;
- (MDBEndpoint *)searchWithQuery:(NSString *)query page:(NSInteger)page;
/// today is passed in so tests get a stable date for the Newest sort.
- (MDBEndpoint *)discoverWithGenreID:(NSInteger)genreID sort:(MDBDiscoverSort)sort page:(NSInteger)page today:(NSDate *)today;
- (MDBEndpoint *)genres;
- (MDBEndpoint *)movieDetailWithID:(NSInteger)movieID;
- (MDBEndpoint *)personWithID:(NSInteger)personID;

@end

NS_ASSUME_NONNULL_END
