//
//  MDBAPIError.m
//  MovieDB
//

#import "MDBAPIError.h"

NSErrorDomain const MDBAPIErrorDomain = @"com.adamappstudio.moviedb.api";
NSString *const MDBAPIErrorStatusCodeKey = @"MDBAPIErrorStatusCode";

@implementation NSError (MDBAPIError)

+ (instancetype)mdb_apiErrorWithCode:(MDBAPIErrorCode)code
                             message:(nullable NSString *)message
                          underlying:(nullable NSError *)underlying {
  NSMutableDictionary<NSErrorUserInfoKey, id> *info = [NSMutableDictionary dictionary];
  if (message.length > 0) {
    info[NSLocalizedDescriptionKey] = message;
  }
  if (underlying) {
    info[NSUnderlyingErrorKey] = underlying;
  }
  return [NSError errorWithDomain:MDBAPIErrorDomain code:code userInfo:info];
}

+ (instancetype)mdb_apiErrorFromTransportError:(NSError *)error {
  if ([error.domain isEqualToString:MDBAPIErrorDomain]) {
    return error;
  }
  if ([error.domain isEqualToString:NSURLErrorDomain]) {
    switch (error.code) {
      case NSURLErrorCancelled:
        return [self mdb_apiErrorWithCode:MDBAPIErrorCancelled message:@"Request cancelled" underlying:error];
      case NSURLErrorNotConnectedToInternet:
      case NSURLErrorNetworkConnectionLost:
      case NSURLErrorDataNotAllowed:
      case NSURLErrorInternationalRoamingOff:
      case NSURLErrorCannotFindHost:
      case NSURLErrorCannotConnectToHost:
      case NSURLErrorDNSLookupFailed:
      case NSURLErrorTimedOut:
        return [self mdb_apiErrorWithCode:MDBAPIErrorOffline message:error.localizedDescription underlying:error];
      default: break;
    }
  }
  return [self mdb_apiErrorWithCode:MDBAPIErrorTransport message:error.localizedDescription underlying:error];
}

+ (instancetype)mdb_apiErrorWithStatusCode:(NSInteger)statusCode message:(nullable NSString *)message {
  MDBAPIErrorCode code = MDBAPIErrorHTTPStatus;
  if (statusCode == 401) {
    code = MDBAPIErrorUnauthorized;
  } else if (statusCode == 404) {
    code = MDBAPIErrorNotFound;
  }
  NSString *text = message.length > 0 ? message : [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
  NSDictionary<NSErrorUserInfoKey, id> *info = @{
    NSLocalizedDescriptionKey : text ?: @"Request failed",
    MDBAPIErrorStatusCodeKey : @(statusCode),
  };
  return [NSError errorWithDomain:MDBAPIErrorDomain code:code userInfo:info];
}

- (BOOL)mdb_isOffline {
  return [self.domain isEqualToString:MDBAPIErrorDomain] && self.code == MDBAPIErrorOffline;
}

- (BOOL)mdb_isCancelled {
  return [self.domain isEqualToString:MDBAPIErrorDomain] && self.code == MDBAPIErrorCancelled;
}

- (BOOL)mdb_isMissingToken {
  return [self.domain isEqualToString:MDBAPIErrorDomain] && self.code == MDBAPIErrorMissingToken;
}

- (NSString *)mdb_userFacingTitle {
  if (![self.domain isEqualToString:MDBAPIErrorDomain]) {
    return @"Something went wrong";
  }
  switch ((MDBAPIErrorCode)self.code) {
    case MDBAPIErrorMissingToken: return @"TMDB token missing";
    case MDBAPIErrorOffline: return @"No internet connection";
    case MDBAPIErrorUnauthorized: return @"TMDB rejected the token";
    case MDBAPIErrorNotFound: return @"Not found";
    default: return @"Something went wrong";
  }
}

- (NSString *)mdb_userFacingMessage {
  if (![self.domain isEqualToString:MDBAPIErrorDomain]) {
    return @"Please try again in a moment.";
  }
  switch ((MDBAPIErrorCode)self.code) {
    case MDBAPIErrorMissingToken: return @"Add your TMDB API Read Access Token to Configs/Secrets.xcconfig, then build again.";
    case MDBAPIErrorOffline:
      return @"We couldn't reach TMDB. Check your connection and try again. Your favorites still work offline.";
    case MDBAPIErrorUnauthorized: return @"Double check the token in Configs/Secrets.xcconfig. It may have been revoked.";
    case MDBAPIErrorNotFound: return @"TMDB doesn't have this item anymore.";
    default: return @"TMDB didn't answer the way we expected. Please try again in a moment.";
  }
}

@end
