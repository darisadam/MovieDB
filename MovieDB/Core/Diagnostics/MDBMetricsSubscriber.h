//
//  MDBMetricsSubscriber.h
//  MovieDB
//
//  Listens for MetricKit payloads (launch time, hangs, crashes, memory) and saves them as JSON
//  in Caches/MetricKit. Payloads arrive at most once a day on a real device, never in the simulator.
//  In Xcode you can force one with Debug > Simulate MetricKit Payloads.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBMetricsSubscriber : NSObject

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (NSURL *)defaultDirectoryURL;

- (void)start;
- (void)stop;

/// Saved payload files, newest first.
- (NSArray<NSURL *> *)savedPayloadURLs;

@end

NS_ASSUME_NONNULL_END
