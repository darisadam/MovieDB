//
//  MDBAPIClient.m
//  MovieDB
//

#import "MDBAPIClient.h"
#import <QuartzCore/QuartzCore.h>
#import "MDBAPIError.h"
#import "MDBEndpoint.h"
#import "MDBLog.h"
#import "MDBNetworkActivityLog.h"
#import "MDBSignpost.h"
#import "MDBTMDBConfiguration.h"
#import "NSDictionary+MDBSafeJSON.h"

#pragma mark - Cancellable wrapper

@interface MDBSessionTaskHandle : NSObject <MDBCancellable>
@property (nonatomic, readonly, nullable) NSURLSessionTask *task;
@end

@implementation MDBSessionTaskHandle

- (instancetype)initWithTask:(nullable NSURLSessionTask *)task {
  self = [super init];
  if (self) {
    _task = task;
  }
  return self;
}

- (void)cancel {
  [self.task cancel];
}

@end

#pragma mark - Session delegate

// The session keeps a strong reference to its delegate, so this lives in its own object
// to avoid a retain cycle between the client and the session.
@interface MDBSessionMetricsDelegate : NSObject <NSURLSessionTaskDelegate>
@end

@implementation MDBSessionMetricsDelegate

- (void)URLSession:(NSURLSession *)session
                          task:(NSURLSessionTask *)task
    didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
  NSURLSessionTaskTransactionMetrics *transaction = metrics.transactionMetrics.lastObject;
  if (!transaction) {
    return;
  }
  double total = metrics.taskInterval.duration * 1000;
  double waiting = 0;
  NSDate *requestEnd = transaction.requestEndDate;
  NSDate *responseStart = transaction.responseStartDate;
  if (requestEnd && responseStart) {
    waiting = [responseStart timeIntervalSinceDate:requestEnd] * 1000;
  }
  NSString *source = transaction.resourceFetchType == NSURLSessionTaskMetricsResourceFetchTypeLocalCache ? @"cache" : @"network";
  MDBLogDebug(MDBLogCategoryNetwork, @"metrics %@ total %.0f ms, server wait %.0f ms, %@, reused connection %@, protocol %@",
              task.originalRequest.URL.path, total, waiting, source, transaction.isReusedConnection ? @"yes" : @"no",
              transaction.networkProtocolName ?: @"n/a");
}

@end

#pragma mark - Client

@interface MDBAPIClient ()
@property (nonatomic, readonly) NSURLSession *session;
@property (nonatomic, readonly) MDBNetworkActivityLog *activityLog;
@end

@implementation MDBAPIClient

- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration activityLog:(MDBNetworkActivityLog *)activityLog {
  NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  sessionConfiguration.waitsForConnectivity = NO;
  sessionConfiguration.timeoutIntervalForRequest = 20;
  sessionConfiguration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:8 * 1024 * 1024 diskCapacity:40 * 1024 * 1024
                                                                directoryURL:nil];
  return [self initWithConfiguration:configuration sessionConfiguration:sessionConfiguration activityLog:activityLog];
}

- (instancetype)initWithConfiguration:(MDBTMDBConfiguration *)configuration
                 sessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                          activityLog:(MDBNetworkActivityLog *)activityLog {
  self = [super init];
  if (self) {
    _configuration = configuration;
    _activityLog = activityLog;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"com.adamappstudio.moviedb.api";
    queue.maxConcurrentOperationCount = 2;
    queue.qualityOfService = NSQualityOfServiceUserInitiated;
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:[[MDBSessionMetricsDelegate alloc] init]
                                        delegateQueue:queue];
  }
  return self;
}

- (void)dealloc {
  [_session finishTasksAndInvalidate];
}

- (id<MDBCancellable>)GET:(MDBEndpoint *)endpoint parser:(MDBAPIParser)parser completion:(MDBAPICompletion)completion {
  NSError *earlyError = nil;
  NSURLRequest *request = nil;
  if (self.simulatesOffline) {
    earlyError = [NSError mdb_apiErrorWithCode:MDBAPIErrorOffline message:@"Offline mode is on in the debug menu" underlying:nil];
  } else if (!self.configuration.hasAccessToken) {
    earlyError = [NSError mdb_apiErrorWithCode:MDBAPIErrorMissingToken message:nil underlying:nil];
  } else {
    request = [endpoint requestWithConfiguration:self.configuration];
    if (!request) {
      earlyError = [NSError mdb_apiErrorWithCode:MDBAPIErrorInvalidRequest message:@"Could not build the request URL"
                                      underlying:nil];
    }
  }

  if (earlyError || !request) {
    MDBLogError(MDBLogCategoryNetwork, @"GET %@ skipped: %@", endpoint.path, earlyError.localizedDescription);
    MDBAPICompletion callback = [completion copy];
    NSError *errorToSend = earlyError;
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(nil, errorToSend);
    });
    return [[MDBSessionTaskHandle alloc] initWithTask:nil];
  }

  MDBLogDebug(MDBLogCategoryNetwork, @"GET %@", request.URL.absoluteString);
  MDBLogDebug(MDBLogCategoryNetwork, @"%@", [MDBNetworkActivityLog cURLCommandForRequest:request]);

  os_signpost_id_t signpostID = [MDBSignpost beginNetworkRequestWithPath:endpoint.path];
  CFTimeInterval startTime = CACurrentMediaTime();
  MDBNetworkActivityLog *activityLog = self.activityLog;
  MDBAPIParser parse = [parser copy];
  MDBAPICompletion callback = [completion copy];

  NSURLSessionDataTask *task = [self.session
      dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *transportError) {
        NSInteger statusCode =
            [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        double elapsed = (CACurrentMediaTime() - startTime) * 1000;
        [MDBSignpost endNetworkRequest:signpostID statusCode:statusCode];

        id result = nil;
        NSError *finalError = nil;

        if (transportError) {
          finalError = [NSError mdb_apiErrorFromTransportError:transportError];
        } else if (statusCode < 200 || statusCode >= 300) {
          NSString *message = nil;
          id body = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
          if ([body isKindOfClass:[NSDictionary class]]) {
            message = [(NSDictionary *)body mdb_stringForKey:@"status_message"];
          }
          finalError = [NSError mdb_apiErrorWithStatusCode:statusCode message:message];
        } else {
          NSError *jsonError = nil;
          id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError] : nil;
          if (!json) {
            finalError = [NSError mdb_apiErrorWithCode:MDBAPIErrorDecoding message:@"Response was not valid JSON"
                                            underlying:jsonError];
          } else {
            result = parse(json);
            if (!result) {
              finalError = [NSError mdb_apiErrorWithCode:MDBAPIErrorDecoding message:@"Unexpected response shape" underlying:nil];
            }
          }
        }

        MDBNetworkActivityEntry *entry = [[MDBNetworkActivityEntry alloc] initWithRequest:request statusCode:statusCode
                                                                     durationMilliseconds:elapsed
                                                                            responseBytes:data.length
                                                                         errorDescription:finalError.localizedDescription];
        [activityLog recordEntry:entry];

        if (finalError.mdb_isCancelled) {
          MDBLogDebug(MDBLogCategoryNetwork, @"cancelled %@", request.URL.path);
        } else if (finalError) {
          MDBLogError(MDBLogCategoryNetwork, @"%@", entry.summary);
        } else {
          MDBLogInfo(MDBLogCategoryNetwork, @"%@", entry.summary);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
          callback(result, finalError);
        });
      }];
  [task resume];
  return [[MDBSessionTaskHandle alloc] initWithTask:task];
}

@end
