//
//  MDBSignpost.h
//  MovieDB
//
//  Intervals that show up in Instruments under Points of Interest.
//  Every network request and every screen's first load is measured.
//

#import <Foundation/Foundation.h>
#import <os/signpost.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBSignpost : NSObject

+ (os_signpost_id_t)beginNetworkRequestWithPath:(NSString *)path;
+ (void)endNetworkRequest:(os_signpost_id_t)signpostID statusCode:(NSInteger)statusCode;

+ (os_signpost_id_t)beginScreenLoad:(NSString *)screenName;
+ (void)endScreenLoad:(os_signpost_id_t)signpostID screenName:(NSString *)screenName;

+ (void)emitEvent:(NSString *)name;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
