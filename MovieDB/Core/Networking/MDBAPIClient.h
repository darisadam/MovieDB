//
//  MDBAPIClient.h
//  MovieDB
//
//  Small NSURLSession wrapper for TMDB. Parsing runs off the main thread,
//  completion always comes back on the main queue.
//

#import <Foundation/Foundation.h>

@class MDBEndpoint;
@class MDBTMDBConfiguration;
@class MDBNetworkActivityLog;

NS_ASSUME_NONNULL_BEGIN

@protocol MDBCancellable <NSObject>
- (void)cancel;
@end

/// Turns the decoded JSON into a model. Return nil if the shape is wrong. Runs on a background queue.
typedef id _Nullable (^MDBAPIParser)(id JSONObject);
/// Called on the main queue. Exactly one of result or error is non nil.
typedef void (^MDBAPICompletion)(id _Nullable result, NSError *_Nullable error);

@interface MDBAPIClient : NSObject

@property (nonatomic, readonly) MDBTMDBConfiguration *configuration;
/// Debug switch to test offline states without touching the device settings.
@property (atomic) BOOL simulatesOffline;

- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration activityLog:(MDBNetworkActivityLog *)activityLog;
- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration
                 sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                          activityLog:(MDBNetworkActivityLog *)activityLog NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (id<MDBCancellable>)GET:(MDBEndpoint *)endpoint parser:(MDBAPIParser)parser completion:(MDBAPICompletion)completion;

@end

NS_ASSUME_NONNULL_END
