//
//  MDBTMDBConfiguration.m
//  MovieDB
//

#import "MDBTMDBConfiguration.h"
#import "MDBLog.h"

static NSString *const MDBTMDBTokenInfoKey = @"TMDBAccessToken";

@implementation MDBTMDBConfiguration

+ (instancetype)configurationWithBundle:(NSBundle *)bundle {
  id value = [bundle objectForInfoDictionaryKey:MDBTMDBTokenInfoKey];
  NSString *token = [value isKindOfClass:[NSString class]] ? value : nil;
  // Both are constant, valid URLs, so the casts only tell the compiler what we already know.
  NSURL *apiBaseURL = (NSURL *_Nonnull)[NSURL URLWithString:@"https://api.themoviedb.org/3/"];
  NSURL *imageBaseURL = (NSURL *_Nonnull)[NSURL URLWithString:@"https://image.tmdb.org/t/p/"];
  MDBTMDBConfiguration *configuration = [[self alloc] initWithAccessToken:token apiBaseURL:apiBaseURL imageBaseURL:imageBaseURL];
  if (!configuration.hasAccessToken) {
    MDBLogError(MDBLogCategoryNetwork, @"TMDB token is missing. Add it to Configs/Secrets.xcconfig and rebuild.");
  }
  return configuration;
}

- (instancetype)initWithAccessToken:(nullable NSString *)accessToken
                         apiBaseURL:(NSURL *)apiBaseURL
                       imageBaseURL:(NSURL *)imageBaseURL {
  self = [super init];
  if (self) {
    NSString *trimmed = [accessToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    // An unexpanded build setting means Secrets.xcconfig was never included.
    if ([trimmed hasPrefix:@"$("]) {
      trimmed = @"";
    }
    _accessToken = [trimmed copy];
    _apiBaseURL = [apiBaseURL copy];
    _imageBaseURL = [imageBaseURL copy];
  }
  return self;
}

- (BOOL)hasAccessToken {
  return self.accessToken.length > 0;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ api=%@ token=%@>", NSStringFromClass([self class]), self.apiBaseURL.absoluteString,
                                    self.hasAccessToken
                                        ? [NSString stringWithFormat:@"set (%lu chars)", (unsigned long)self.accessToken.length]
                                        : @"missing"];
}

- (NSString *)debugDescription {
  return [self description];
}

@end
