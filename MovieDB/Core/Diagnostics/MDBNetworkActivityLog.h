//
//  MDBNetworkActivityLog.h
//  MovieDB
//
//  Keeps the last N requests in memory so the debug menu and LLDB can show them.
//  Safe to use from any thread.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBNetworkActivityEntry : NSObject

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, copy, readonly) NSString *method;
@property (nonatomic, copy, readonly) NSString *URLString;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) double durationMilliseconds;
@property (nonatomic, readonly) NSUInteger responseBytes;
@property (nonatomic, copy, readonly, nullable) NSString *errorDescription;
@property (nonatomic, copy, readonly) NSString *cURLCommand;

- (instancetype)initWithRequest:(NSURLRequest *)request
                     statusCode:(NSInteger)statusCode
           durationMilliseconds:(double)durationMilliseconds
                  responseBytes:(NSUInteger)responseBytes
               errorDescription:(nullable NSString *)errorDescription NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// "200 GET /3/movie/popular?page=1 182 ms 12.4 KB"
- (NSString *)summary;

@end

@interface MDBNetworkActivityLog : NSObject

- (instancetype)initWithCapacity:(NSUInteger)capacity NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

- (void)recordEntry:(MDBNetworkActivityEntry *)entry;
/// Newest first.
- (NSArray<MDBNetworkActivityEntry *> *)recentEntries;
- (void)clear;

/// A cURL command you can paste in Terminal. The Authorization header is always redacted.
+ (NSString *)cURLCommandForRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
