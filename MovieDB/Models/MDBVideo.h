//
//  MDBVideo.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBVideo : NSObject

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *site;
/// "Trailer", "Teaser", "Featurette", "Clip" and so on.
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, readonly, getter=isOfficial) BOOL official;
@property (nonatomic, copy, readonly, nullable) NSDate *publishedAt;

@property (nonatomic, readonly, getter=isYouTube) BOOL youTube;
@property (nonatomic, readonly, nullable) NSURL *watchURL;
@property (nonatomic, readonly, nullable) NSURL *thumbnailURL;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// YouTube only, trailers first, official before unofficial, newest first.
+ (NSArray<MDBVideo *> *)playableVideosFromJSONArray:(nullable NSArray *)array;

@end

NS_ASSUME_NONNULL_END
