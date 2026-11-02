//
//  MDBEndpoint.h
//  MovieDB
//

#import <Foundation/Foundation.h>

@class MDBTMDBConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface MDBEndpoint : NSObject

/// Relative to the API base URL, without a leading slash. For example "movie/popular".
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *query;

+ (instancetype)endpointWithPath:(NSString *)path query:(nullable NSDictionary<NSString *, NSString *> *)query;

- (instancetype)initWithPath:(NSString *)path
                       query:(nullable NSDictionary<NSString *, NSString *> *)query NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Query items are sorted by name so the same endpoint always gives the same URL. Handy for caching and tests.
- (nullable NSURL *)URLWithBaseURL:(NSURL *)baseURL;
/// A GET request with the bearer token. Nil if the URL can't be built.
- (nullable NSURLRequest *)requestWithConfiguration:(MDBTMDBConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
