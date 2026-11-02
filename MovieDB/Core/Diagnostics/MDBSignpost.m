//
//  MDBSignpost.m
//  MovieDB
//

#import "MDBSignpost.h"
#import "MDBLog.h"

@implementation MDBSignpost

+ (os_log_t)pointsOfInterest {
    static os_log_t log;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        log = os_log_create(MDBLogSubsystem.UTF8String, "PointsOfInterest");
    });
    return log;
}

+ (os_signpost_id_t)beginNetworkRequestWithPath:(NSString *)path {
    os_log_t log = [self pointsOfInterest];
    os_signpost_id_t signpostID = os_signpost_id_generate(log);
    os_signpost_interval_begin(log, signpostID, "Network Request", "%{public}@", path);
    return signpostID;
}

+ (void)endNetworkRequest:(os_signpost_id_t)signpostID statusCode:(NSInteger)statusCode {
    os_signpost_interval_end([self pointsOfInterest], signpostID, "Network Request", "status %ld", (long)statusCode);
}

+ (os_signpost_id_t)beginScreenLoad:(NSString *)screenName {
    os_log_t log = [self pointsOfInterest];
    os_signpost_id_t signpostID = os_signpost_id_generate(log);
    os_signpost_interval_begin(log, signpostID, "Screen Load", "%{public}@", screenName);
    return signpostID;
}

+ (void)endScreenLoad:(os_signpost_id_t)signpostID screenName:(NSString *)screenName {
    os_signpost_interval_end([self pointsOfInterest], signpostID, "Screen Load", "%{public}@", screenName);
}

+ (void)emitEvent:(NSString *)name {
    os_signpost_event_emit([self pointsOfInterest], OS_SIGNPOST_ID_EXCLUSIVE, "Event", "%{public}@", name);
}

@end
