//
//  MDBMetricsSubscriber.m
//  MovieDB
//

#import "MDBMetricsSubscriber.h"
#import <MetricKit/MetricKit.h>
#import "MDBLog.h"

@interface MDBMetricsSubscriber () <MXMetricManagerSubscriber>
@property (nonatomic, readonly) NSURL *directoryURL;
@property (nonatomic, getter=isRunning) BOOL running;
@end

@implementation MDBMetricsSubscriber

+ (NSURL *)defaultDirectoryURL {
  NSURL *caches = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
  if (!caches) {
    caches = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
  }
  NSURL *folder = [caches URLByAppendingPathComponent:@"MetricKit" isDirectory:YES];
  return folder ?: caches;
}

- (instancetype)initWithDirectoryURL:(NSURL *)directoryURL {
  self = [super init];
  if (self) {
    _directoryURL = [directoryURL copy];
  }
  return self;
}

- (void)dealloc {
  if (_running) {
    [[MXMetricManager sharedManager] removeSubscriber:self];
  }
}

- (void)start {
  if (self.isRunning) {
    return;
  }
  self.running = YES;
  [[MXMetricManager sharedManager] addSubscriber:self];
  MDBLogInfo(MDBLogCategoryMetrics, @"MetricKit subscriber started, saving to %@", self.directoryURL.path);
}

- (void)stop {
  if (!self.isRunning) {
    return;
  }
  self.running = NO;
  [[MXMetricManager sharedManager] removeSubscriber:self];
}

- (NSArray<NSURL *> *)savedPayloadURLs {
  NSArray<NSURL *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.directoryURL
                                                          includingPropertiesForKeys:nil
                                                                             options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                               error:nil];
  NSArray<NSURL *> *sorted = [files sortedArrayUsingComparator:^NSComparisonResult(NSURL *lhs, NSURL *rhs) {
    NSString *left = lhs.lastPathComponent ?: @"";
    NSString *right = rhs.lastPathComponent ?: @"";
    return [right compare:left];
  }];
  return sorted ?: @[];
}

#pragma mark - MXMetricManagerSubscriber

- (void)didReceiveMetricPayloads:(NSArray<MXMetricPayload *> *)payloads {
  for (MXMetricPayload *payload in payloads) {
    NSTimeInterval launchMs = 0;
    MXHistogram<NSUnitDuration *> *launches = payload.applicationLaunchMetrics.histogrammedTimeToFirstDraw;
    if (launches.totalBucketCount > 0) {
      MXHistogramBucket<NSUnitDuration *> *bucket = launches.bucketEnumerator.nextObject;
      launchMs = [bucket.bucketStart measurementByConvertingToUnit:NSUnitDuration.milliseconds].doubleValue;
    }
    MDBLogInfo(MDBLogCategoryMetrics, @"Metric payload %@ to %@, first launch bucket %.0f ms", payload.timeStampBegin,
               payload.timeStampEnd, launchMs);
    [self savePayloadData:payload.JSONRepresentation prefix:@"metrics"];
  }
}

- (void)didReceiveDiagnosticPayloads:(NSArray<MXDiagnosticPayload *> *)payloads {
  for (MXDiagnosticPayload *payload in payloads) {
    NSUInteger launchIssues = 0;
    if (@available(iOS 16.0, *)) {
      launchIssues = payload.appLaunchDiagnostics.count;
    }
    MDBLogError(MDBLogCategoryMetrics, @"Diagnostic payload: %lu crashes, %lu hangs, %lu CPU, %lu disk writes, %lu slow launches",
                (unsigned long)payload.crashDiagnostics.count, (unsigned long)payload.hangDiagnostics.count,
                (unsigned long)payload.cpuExceptionDiagnostics.count, (unsigned long)payload.diskWriteExceptionDiagnostics.count,
                (unsigned long)launchIssues);
    [self savePayloadData:payload.JSONRepresentation prefix:@"diagnostics"];
  }
}

#pragma mark - Private

- (void)savePayloadData:(NSData *)data prefix:(NSString *)prefix {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  if (![fileManager createDirectoryAtURL:self.directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
    MDBLogError(MDBLogCategoryMetrics, @"Could not create MetricKit folder: %@", error.localizedDescription);
    return;
  }
  NSString *name = [NSString stringWithFormat:@"%.0f-%@.json", [[NSDate date] timeIntervalSince1970], prefix];
  NSURL *fileURL = [self.directoryURL URLByAppendingPathComponent:name];
  if (![data writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
    MDBLogError(MDBLogCategoryMetrics, @"Could not save MetricKit payload: %@", error.localizedDescription);
  }
}

@end
