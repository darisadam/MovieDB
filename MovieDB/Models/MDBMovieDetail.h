//
//  MDBMovieDetail.h
//  MovieDB
//
//  Built from /movie/{id}?append_to_response=credits,videos,recommendations
//

#import <Foundation/Foundation.h>

@class MDBMovie;
@class MDBGenre;
@class MDBCastMember;
@class MDBVideo;

NS_ASSUME_NONNULL_BEGIN

@interface MDBMovieDetail : NSObject

@property (nonatomic, readonly) MDBMovie *movie;
@property (nonatomic, readonly) NSInteger runtimeMinutes;
@property (nonatomic, copy, readonly, nullable) NSString *tagline;
@property (nonatomic, copy, readonly, nullable) NSString *status;
@property (nonatomic, copy, readonly, nullable) NSString *originalLanguageName;
@property (nonatomic, readonly) long long budget;
@property (nonatomic, readonly) long long revenue;
@property (nonatomic, copy, readonly) NSArray<MDBGenre *> *genres;
@property (nonatomic, copy, readonly) NSArray<MDBCastMember *> *cast;
@property (nonatomic, copy, readonly) NSArray<MDBVideo *> *videos;
@property (nonatomic, copy, readonly) NSArray<MDBMovie *> *recommendations;

@property (nonatomic, readonly, nullable) MDBVideo *preferredTrailer;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
