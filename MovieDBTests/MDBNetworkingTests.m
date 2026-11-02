//
//  MDBNetworkingTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBAPIClient.h"
#import "MDBAPIError.h"
#import "MDBEndpoint.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBNetworkActivityLog.h"
#import "MDBObservable.h"
#import "MDBPreferences.h"
#import "MDBTMDBConfiguration.h"
#import "MDBTMDBMovieService.h"
#import "MDBTestSupport.h"

#pragma mark - URL protocol stub

static NSInteger MDBStubStatusCode = 200;
static NSData *MDBStubBody = nil;
static NSURLRequest *MDBStubLastRequest = nil;

@interface MDBStubURLProtocol : NSURLProtocol
@end

@implementation MDBStubURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (void)startLoading {
  MDBStubLastRequest = self.request;
  NSURL *url = self.request.URL ?: MDBTestURL(@"https://example.com");
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:MDBStubStatusCode HTTPVersion:@"HTTP/1.1"
                                                          headerFields:@{@"Content-Type" : @"application/json"}];
  [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  [self.client URLProtocol:self didLoadData:MDBStubBody ?: [NSData data]];
  [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
}

@end

#pragma mark - Tests

@interface MDBNetworkingTests : XCTestCase
@property (nonatomic) MDBTMDBConfiguration *configuration;
@property (nonatomic) MDBNetworkActivityLog *log;
@property (nonatomic) MDBAPIClient *client;
@end

@implementation MDBNetworkingTests

- (void)setUp {
  [super setUp];
  MDBStubStatusCode = 200;
  MDBStubBody = nil;
  MDBStubLastRequest = nil;
  self.configuration = [[MDBTMDBConfiguration alloc] initWithAccessToken:@"test-token-123"
                                                              apiBaseURL:MDBTestURL(@"https://api.themoviedb.org/3/")
                                                            imageBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
  self.log = [[MDBNetworkActivityLog alloc] initWithCapacity:3];
  NSURLSessionConfiguration *session = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  session.protocolClasses = @[ [MDBStubURLProtocol class] ];
  self.client = [[MDBAPIClient alloc] initWithConfiguration:self.configuration sessionConfiguration:session activityLog:self.log];
}

- (void)testEndpointSortsQueryAndAddsBearerToken {
  MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:@"/movie/popular" query:@{@"page" : @"2", @"language" : @"en-US"}];
  NSURLRequest *request = [endpoint requestWithConfiguration:self.configuration];
  XCTAssertEqualObjects(request.URL.absoluteString, @"https://api.themoviedb.org/3/movie/popular?language=en-US&page=2");
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Authorization"], @"Bearer test-token-123");
  XCTAssertFalse([request.URL.absoluteString containsString:@"test-token"], @"The token must never end up in the URL");
}

- (void)testEndpointEncodesSearchText {
  MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:@"search/movie" query:@{@"query" : @"Amélie & friends"}];
  NSURL *url = [endpoint URLWithBaseURL:self.configuration.apiBaseURL];
  XCTAssertEqualObjects(url.absoluteString, @"https://api.themoviedb.org/3/search/movie?query=Am%C3%A9lie%20%26%20friends");
}

- (void)testConfigurationTreatsUnexpandedSettingAsMissing {
  MDBTMDBConfiguration *configuration = [[MDBTMDBConfiguration alloc] initWithAccessToken:@"$(TMDB_ACCESS_TOKEN)"
                                                                               apiBaseURL:self.configuration.apiBaseURL
                                                                             imageBaseURL:self.configuration.imageBaseURL];
  XCTAssertFalse(configuration.hasAccessToken);
  XCTAssertFalse([self.configuration.description containsString:@"test-token"], @"description must not print the token");
}

- (void)testImageURLBuilder {
  MDBImageURLBuilder *builder = [[MDBImageURLBuilder alloc] initWithBaseURL:self.configuration.imageBaseURL];
  XCTAssertEqualObjects([builder URLForPath:@"/abc.jpg" size:MDBImageSizePoster].absoluteString,
                        @"https://image.tmdb.org/t/p/w342/abc.jpg");
  XCTAssertNil([builder URLForPath:nil size:MDBImageSizePoster]);
  XCTAssertNil([builder URLForPath:@"" size:MDBImageSizeBackdrop]);
}

- (void)testSuccessfulResponseIsParsedAndLogged {
  MDBStubBody = [@"{\"value\": 42}" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *done = [self expectationWithDescription:@"completion"];
  [self.client GET:[MDBEndpoint endpointWithPath:@"movie/1" query:nil] parser:^id(id JSON) {
    return JSON[@"value"];
  } completion:^(id result, NSError *error) {
    XCTAssertTrue([NSThread isMainThread]);
    XCTAssertNil(error);
    XCTAssertEqualObjects(result, @42);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];

  MDBNetworkActivityEntry *entry = [self.log recentEntries].firstObject;
  XCTAssertEqual(entry.statusCode, 200);
  XCTAssertTrue([entry.cURLCommand containsString:@"Bearer <redacted>"]);
  XCTAssertFalse([entry.cURLCommand containsString:@"test-token-123"]);
}

- (void)testUnauthorizedResponseMapsToUnauthorizedError {
  MDBStubStatusCode = 401;
  MDBStubBody = [@"{\"status_message\": \"Invalid API key\"}" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *done = [self expectationWithDescription:@"completion"];
  [self.client GET:[MDBEndpoint endpointWithPath:@"movie/1" query:nil] parser:^id(id JSON) {
    return JSON;
  } completion:^(id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(error.domain, MDBAPIErrorDomain);
    XCTAssertEqual(error.code, MDBAPIErrorUnauthorized);
    XCTAssertEqualObjects(error.localizedDescription, @"Invalid API key");
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testParserReturningNilIsADecodingError {
  MDBStubBody = [@"[1, 2, 3]" dataUsingEncoding:NSUTF8StringEncoding];
  XCTestExpectation *done = [self expectationWithDescription:@"completion"];
  [self.client GET:[MDBEndpoint endpointWithPath:@"movie/1" query:nil] parser:^id(id JSON) {
    return [JSON isKindOfClass:[NSDictionary class]] ? JSON : nil;
  } completion:^(id result, NSError *error) {
    XCTAssertEqual(error.code, MDBAPIErrorDecoding);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testMissingTokenFailsWithoutTouchingTheNetwork {
  MDBTMDBConfiguration *empty = [[MDBTMDBConfiguration alloc] initWithAccessToken:@"" apiBaseURL:self.configuration.apiBaseURL
                                                                     imageBaseURL:self.configuration.imageBaseURL];
  NSURLSessionConfiguration *session = [NSURLSessionConfiguration ephemeralSessionConfiguration];
  session.protocolClasses = @[ [MDBStubURLProtocol class] ];
  MDBAPIClient *client = [[MDBAPIClient alloc] initWithConfiguration:empty sessionConfiguration:session activityLog:self.log];

  XCTestExpectation *done = [self expectationWithDescription:@"completion"];
  [client GET:[MDBEndpoint endpointWithPath:@"movie/1" query:nil] parser:^id(id JSON) {
    return JSON;
  } completion:^(id result, NSError *error) {
    XCTAssertTrue(error.mdb_isMissingToken);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertNil(MDBStubLastRequest);
}

- (void)testSimulatedOfflineMode {
  self.client.simulatesOffline = YES;
  XCTestExpectation *done = [self expectationWithDescription:@"completion"];
  [self.client GET:[MDBEndpoint endpointWithPath:@"movie/1" query:nil] parser:^id(id JSON) {
    return JSON;
  } completion:^(id result, NSError *error) {
    XCTAssertTrue(error.mdb_isOffline);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testActivityLogKeepsOnlyTheNewestEntries {
  NSURLRequest *request = [NSURLRequest requestWithURL:MDBTestURL(@"https://example.com")];
  for (NSInteger index = 0; index < 5; index++) {
    [self.log recordEntry:[[MDBNetworkActivityEntry alloc] initWithRequest:request statusCode:200 + index durationMilliseconds:1
                                                             responseBytes:0
                                                          errorDescription:nil]];
  }
  NSArray<MDBNetworkActivityEntry *> *entries = [self.log recentEntries];
  XCTAssertEqual(entries.count, 3u);
  XCTAssertEqual(entries.firstObject.statusCode, 204);
}

- (void)testServiceFetchesGenresAndPublishesNames {
  MDBStubBody = [NSJSONSerialization dataWithJSONObject:MDBLoadFixture(@"genres") options:0 error:nil];
  NSString *suite = [NSString stringWithFormat:@"MovieDBTests.%@", [NSUUID UUID].UUIDString];
  MDBPreferences *preferences = [[MDBPreferences alloc] initWithUserDefaults:MDBTestDefaults(suite)];
  MDBTMDBMovieService *service = [[MDBTMDBMovieService alloc] initWithClient:self.client preferences:preferences];
  XCTAssertEqual(service.genreNames.value.count, 0u);

  XCTestExpectation *done = [self expectationWithDescription:@"genres"];
  [service fetchGenresWithCompletion:^(NSArray<MDBGenre *> *genres, NSError *error) {
    XCTAssertNil(error);
    XCTAssertEqual(genres.count, 4u);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertEqualObjects(service.genreNames.value[@28], @"Action");
  XCTAssertTrue([MDBStubLastRequest.URL.absoluteString hasPrefix:@"https://api.themoviedb.org/3/genre/movie/list?language="]);
  [[[NSUserDefaults alloc] initWithSuiteName:suite] removePersistentDomainForName:suite];
}

@end
