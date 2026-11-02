//
//  MDBMovie.h
//  MovieDB
//
//  A movie as it appears in TMDB list responses (popular, search, discover and so on).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovie : NSObject <NSCopying>

@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *overview;
@property (nonatomic, copy, readonly, nullable) NSString *posterPath;
@property (nonatomic, copy, readonly, nullable) NSString *backdropPath;
@property (nonatomic, copy, readonly, nullable) NSDate *releaseDate;
@property (nonatomic, readonly) double voteAverage;
@property (nonatomic, readonly) NSInteger voteCount;
@property (nonatomic, readonly) double popularity;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *genreIDs;

/// Nil when the id or title is missing.
- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;

- (instancetype)initWithMovieID:(NSInteger)movieID
                          title:(NSString *)title
                       overview:(nullable NSString *)overview
                     posterPath:(nullable NSString *)posterPath
                   backdropPath:(nullable NSString *)backdropPath
                    releaseDate:(nullable NSDate *)releaseDate
                    voteAverage:(double)voteAverage
                      voteCount:(NSInteger)voteCount
                     popularity:(double)popularity
                       genreIDs:(nullable NSArray<NSNumber *> *)genreIDs NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Parses an array of movie dictionaries and drops the ones that fail.
+ (NSArray<MDBMovie *> *)moviesFromJSONArray:(nullable NSArray *)array;

@end

NS_ASSUME_NONNULL_END
