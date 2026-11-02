//
//  MDBPagerTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBMovie.h"
#import "MDBMoviePager.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBScreenState.h"
#import "MDBTestSupport.h"

@interface MDBPagerTests : XCTestCase
@property (nonatomic) MDBStubMovieService *service;
@property (nonatomic) MDBMoviePager *pager;
@end

@implementation MDBPagerTests

- (void)setUp {
  [super setUp];
  self.service = [[MDBStubMovieService alloc] init];
  self.pager = [[MDBMoviePager alloc] initWithPrefetchDistance:2];
}

- (void)start {
  MDBStubMovieService *service = self.service;
  [self.pager startWithRequest:^id<MDBCancellable>(NSInteger page, MDBMoviePageCompletion completion) {
    return [service fetchMovieList:MDBMovieListKindPopular page:page completion:completion];
  }];
}

- (MDBScreenState<MDBPagedMovies *> *)waitForLoaded {
  MDBPagerTests *test = self;
  MDBWaitUntil(^BOOL {
    MDBScreenState *state = test.pager.state.value;
    return state.phase != MDBLoadStateLoading && !((MDBPagedMovies *)state.content).isLoadingMore;
  });
  return self.pager.state.value;
}

- (void)testFirstPageLoads {
  self.service.pagesByNumber = @{@1 : [MDBStubMovieService pageNumber:1 of:3 firstID:1 count:5]};
  [self start];
  XCTAssertEqual(self.pager.state.value.phase, MDBLoadStateLoading);
  MDBScreenState<MDBPagedMovies *> *state = [self waitForLoaded];
  XCTAssertEqual(state.phase, MDBLoadStateLoaded);
  XCTAssertEqual(state.content.movies.count, 5u);
  XCTAssertEqual(state.content.totalResults, 15);
}

- (void)testLoadsMoreNearTheEndAndDropsDuplicates {
  self.service.pagesByNumber = @{
    @1 : [MDBStubMovieService pageNumber:1 of:2 firstID:1 count:5],
    // Page 2 repeats id 5, which happens when TMDB rankings shift between calls.
    @2 : [MDBStubMovieService pageNumber:2 of:2 firstID:5 count:5],
  };
  [self start];
  [self waitForLoaded];

  [self.pager loadMoreIfNeededForIndex:0];
  XCTAssertEqualObjects(self.service.requestedPages, @[ @1 ], @"Too far from the end to prefetch");

  [self.pager loadMoreIfNeededForIndex:4];
  XCTAssertTrue(self.pager.state.value.content.isLoadingMore);
  MDBScreenState<MDBPagedMovies *> *state = [self waitForLoaded];
  XCTAssertEqualObjects(self.service.requestedPages, (@[ @1, @2 ]));
  XCTAssertEqual(state.content.movies.count, 9u);

  [self.pager loadMoreIfNeededForIndex:8];
  XCTAssertEqual(self.service.requestedPages.count, 2u, @"Last page reached, no more requests");
}

- (void)testEmptyFirstPage {
  self.service.pagesByNumber = @{@1 : [MDBStubMovieService pageWithTitles:@[]]};
  [self start];
  XCTAssertEqual([self waitForLoaded].phase, MDBLoadStateEmpty);
}

- (void)testFailedFirstPage {
  self.service.listError = [NSError errorWithDomain:@"test" code:3 userInfo:nil];
  [self start];
  MDBScreenState *state = [self waitForLoaded];
  XCTAssertEqual(state.phase, MDBLoadStateFailed);
  XCTAssertEqual(state.error.code, 3);
}

- (void)testResetIgnoresAnswersFromTheOldRequest {
  self.service.pagesByNumber = @{@1 : [MDBStubMovieService pageNumber:1 of:1 firstID:1 count:3]};
  [self start];
  [self.pager reset];
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  XCTAssertEqual(self.pager.state.value.phase, MDBLoadStateIdle);
}

- (void)testShowLoadingClearsOldResults {
  self.service.pagesByNumber = @{@1 : [MDBStubMovieService pageNumber:1 of:1 firstID:1 count:3]};
  [self start];
  [self waitForLoaded];
  [self.pager showLoading];
  XCTAssertTrue(self.pager.state.value.isLoading);
  XCTAssertNil(self.pager.state.value.content);
}

@end
