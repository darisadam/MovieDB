//
//  MDBNetworkActivityLog.m
//  MovieDB
//

#import "MDBNetworkActivityLog.h"

@implementation MDBNetworkActivityEntry

- (instancetype)initWithRequest:(NSURLRequest *)request
                     statusCode:(NSInteger)statusCode
           durationMilliseconds:(double)durationMilliseconds
                  responseBytes:(NSUInteger)responseBytes
               errorDescription:(nullable NSString *)errorDescription {
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _method = [request.HTTPMethod copy] ?: @"GET";
        _URLString = [request.URL.absoluteString copy] ?: @"";
        _statusCode = statusCode;
        _durationMilliseconds = durationMilliseconds;
        _responseBytes = responseBytes;
        _errorDescription = [errorDescription copy];
        _cURLCommand = [[MDBNetworkActivityLog cURLCommandForRequest:request] copy];
    }
    return self;
}

- (NSString *)summary {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.URLString];
    NSString *pathAndQuery = components.percentEncodedQuery.length > 0
        ? [NSString stringWithFormat:@"%@?%@", components.percentEncodedPath, components.percentEncodedQuery]
        : (components.percentEncodedPath ?: self.URLString);
    NSString *status = self.statusCode > 0 ? [NSString stringWithFormat:@"%ld", (long)self.statusCode] : @"ERR";
    NSString *size = [NSByteCountFormatter stringFromByteCount:(long long)self.responseBytes
                                                    countStyle:NSByteCountFormatterCountStyleFile];
    NSMutableString *summary = [NSMutableString stringWithFormat:@"%@ %@ %@ %.0f ms %@",
                                status, self.method, pathAndQuery, self.durationMilliseconds, size];
    if (self.errorDescription.length > 0) {
        [summary appendFormat:@" (%@)", self.errorDescription];
    }
    return [summary copy];
}

- (NSString *)description {
    return [self summary];
}

@end

@interface MDBNetworkActivityLog ()
@property (nonatomic, readonly) NSUInteger capacity;
@property (nonatomic, readonly) NSMutableArray<MDBNetworkActivityEntry *> *entries;
@property (nonatomic, readonly) dispatch_queue_t queue;
@end

@implementation MDBNetworkActivityLog

- (instancetype)init {
    return [self initWithCapacity:100];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        _capacity = MAX((NSUInteger)1, capacity);
        _entries = [NSMutableArray arrayWithCapacity:_capacity];
        _queue = dispatch_queue_create("com.darisadam.MovieDB.network-activity", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)recordEntry:(MDBNetworkActivityEntry *)entry {
    NSMutableArray<MDBNetworkActivityEntry *> *entries = self.entries;
    NSUInteger capacity = self.capacity;
    dispatch_async(self.queue, ^{
        [entries insertObject:entry atIndex:0];
        if (entries.count > capacity) {
            [entries removeObjectsInRange:NSMakeRange(capacity, entries.count - capacity)];
        }
    });
}

- (NSArray<MDBNetworkActivityEntry *> *)recentEntries {
    __block NSArray<MDBNetworkActivityEntry *> *snapshot = @[];
    NSMutableArray<MDBNetworkActivityEntry *> *entries = self.entries;
    dispatch_sync(self.queue, ^{
        snapshot = [entries copy];
    });
    return snapshot;
}

- (void)clear {
    NSMutableArray<MDBNetworkActivityEntry *> *entries = self.entries;
    dispatch_async(self.queue, ^{
        [entries removeAllObjects];
    });
}

+ (NSString *)cURLCommandForRequest:(NSURLRequest *)request {
    NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObject:@"curl"];
    NSString *method = request.HTTPMethod ?: @"GET";
    if (![method isEqualToString:@"GET"]) {
        [parts addObject:[NSString stringWithFormat:@"-X %@", method]];
    }
    NSArray<NSString *> *headerNames = [request.allHTTPHeaderFields.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *name in headerNames) {
        NSString *value = request.allHTTPHeaderFields[name];
        if ([name caseInsensitiveCompare:@"Authorization"] == NSOrderedSame) {
            value = @"Bearer <redacted>";
        }
        [parts addObject:[NSString stringWithFormat:@"-H '%@: %@'", name, value]];
    }
    [parts addObject:[NSString stringWithFormat:@"'%@'", request.URL.absoluteString ?: @""]];
    return [parts componentsJoinedByString:@" "];
}

@end
