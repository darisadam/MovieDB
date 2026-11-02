//
//  MDBEndpoint.m
//  MovieDB
//

#import "MDBEndpoint.h"
#import "MDBTMDBConfiguration.h"

@implementation MDBEndpoint

+ (instancetype)endpointWithPath:(NSString *)path query:(nullable NSDictionary<NSString *, NSString *> *)query {
  return [[self alloc] initWithPath:path query:query];
}

- (instancetype)initWithPath:(NSString *)path query:(nullable NSDictionary<NSString *, NSString *> *)query {
  self = [super init];
  if (self) {
    NSString *cleanPath = path;
    while ([cleanPath hasPrefix:@"/"]) {
      cleanPath = [cleanPath substringFromIndex:1];
    }
    _path = [cleanPath copy];
    _query = [query copy] ?: @{};
  }
  return self;
}

- (nullable NSURL *)URLWithBaseURL:(NSURL *)baseURL {
  NSURL *joined = [NSURL URLWithString:self.path relativeToURL:baseURL];
  if (!joined) {
    return nil;
  }
  NSURLComponents *components = [NSURLComponents componentsWithURL:joined resolvingAgainstBaseURL:YES];
  if (self.query.count > 0) {
    NSArray<NSString *> *names = [self.query.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray arrayWithCapacity:names.count];
    for (NSString *name in names) {
      [items addObject:[NSURLQueryItem queryItemWithName:name value:self.query[name]]];
    }
    components.queryItems = items;
  }
  return components.URL;
}

- (nullable NSURLRequest *)requestWithConfiguration:(MDBTMDBConfiguration *)configuration {
  NSURL *url = [self URLWithBaseURL:configuration.apiBaseURL];
  if (!url) {
    return nil;
  }
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  request.HTTPMethod = @"GET";
  request.timeoutInterval = 20;
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  if (configuration.hasAccessToken) {
    [request setValue:[@"Bearer " stringByAppendingString:configuration.accessToken] forHTTPHeaderField:@"Authorization"];
  }
  return [request copy];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %@ %@>", NSStringFromClass([self class]), self.path, self.query];
}

@end
