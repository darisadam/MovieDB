//
//  MDBViewModelTests.m
//  MovieDBTests
//
//  Home and Explore, the two view models with the most moving parts.
//

#import <XCTest/XCTest.h>
#import "MDBAPIError.h"
#import "MDBExploreViewModel.h"
#import "MDBGenre.h"
#import "MDBHomeViewModel.h"
#import "MDBImageURLBuilder.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBPagedItems.h"
#import "MDBPreferences.h"
#import "MDBScreenState.h"
#import "MDBTestSupport.h"

@interface MDBViewModelTests : XCTestCase
@property (nonatomic) MDBStubMovieService *service;
@property (nonatomic) MDBImageURLBuilder *imageURLs;
@property (nonatomic) MDBSubject<MDBPreferenceSnapshot *> *preferences;
@end

@implementation MDBViewModelTests

- (void)setUp {
  [super setUp];
  self.service = [[MDBStubMovieService alloc] init];
  self.imageURLs = [[MDBImageURLBuilder alloc] initWithBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
  self.preferences = [[MDBSubject alloc] initWithValue:[self snapshotWithRegion:@"US"]];
}

- (MDBPreferenceSnapshot *)snapshotWithRegion:(NSString *)region {
  return [[MDBPreferenceSnapshot alloc] initWithLanguage:[[MDBPreferenceOption alloc] initWithCode:@"en-US" title:@"English"]
                                                  region:[[MDBPreferenceOption alloc] initWithCode:region title:region]];
}

#pragma mark - Home

- (MDBHomeViewModel *)homeViewModel {
  return [[MDBHomeViewModel alloc] initWithServices:self.service imageURLs:self.imageURLs preferences:self.preferences];
}

- (void)testHomeBuildsCarouselAndSections {
  self.service.listPages = @{
    @(MDBMovieListKindNowPlaying) : [MDBStubMovieService pageWithTitles:@[ @"A", @"B" ]],
    @(MDBMovieListKindPopular) : [MDBStubMovieService pageWithTitles:@[ @"C" ]],
    @(MDBMovieListKindTopRated) : [MDBStubMovieService pageWithTitles:@[ @"D", @"E", @"F" ]],
  };
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel loadIfNeeded];
  XCTAssertTrue(viewModel.state.value.isLoading);

  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  MDBHomeContent *content = viewModel.state.value.content;
  XCTAssertEqual(content.carouselItems.count, 2u);
  // Upcoming came back empty so it's left out instead of showing an empty row.
  XCTAssertEqual(content.sections.count, 2u);
  XCTAssertEqual(content.sections[1].kind, MDBMovieListKindTopRated);
  XCTAssertEqualObjects(content.sections[0].items.firstObject.metaText, @"2017 · Action");
}

- (void)testHomeRefreshesSubtitlesWhenGenresArrive {
  [self.service.genreNamesSubject send:@{}];
  self.service.listPages = @{@(MDBMovieListKindPopular) : [MDBStubMovieService pageWithTitles:@[ @"A" ]]};
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel reload];
  MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  });
  XCTAssertEqualObjects(viewModel.state.value.content.sections.firstObject.items.firstObject.metaText, @"2017");
  [self.service.genreNamesSubject send:@{@28 : @"Action"}];
  XCTAssertEqualObjects(viewModel.state.value.content.sections.firstObject.items.firstObject.metaText, @"2017 · Action");
}

- (void)testHomeFailsWhenEveryListFails {
  self.service.listError = [NSError mdb_apiErrorWithCode:MDBAPIErrorOffline message:nil underlying:nil];
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel reload];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateFailed;
  }));
  XCTAssertTrue(viewModel.state.value.error.mdb_isOffline);
}

- (void)testHomeIsEmptyWhenNothingCameBack {
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel reload];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateEmpty;
  }));
}

- (void)testHomeLoadIfNeededDoesNotReloadLoadedContent {
  self.service.listPages = @{@(MDBMovieListKindPopular) : [MDBStubMovieService pageWithTitles:@[ @"A" ]]};
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel loadIfNeeded];
  MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  });
  NSUInteger requests = self.service.listRequestCount;
  [viewModel loadIfNeeded];
  XCTAssertEqual(self.service.listRequestCount, requests);
}

- (void)testHomeReloadsWhenRegionChanges {
  self.service.listPages = @{@(MDBMovieListKindPopular) : [MDBStubMovieService pageWithTitles:@[ @"A" ]]};
  MDBHomeViewModel *viewModel = [self homeViewModel];
  [viewModel loadIfNeeded];
  MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  });
  NSUInteger requests = self.service.listRequestCount;
  [self.preferences send:[self snapshotWithRegion:@"ID"]];
  XCTAssertEqual(self.service.listRequestCount, requests + 4);
}

#pragma mark - Explore

- (MDBExploreViewModel *)exploreViewModel {
  return [[MDBExploreViewModel alloc] initWithServices:self.service imageURLs:self.imageURLs preferences:self.preferences
                                      debounceInterval:0.05];
}

- (void)testExploreBrowseShowsTrendingAndGenreShortcuts {
  self.service.listPages = @{@(MDBMovieListKindTrending) : [MDBStubMovieService pageWithTitles:@[ @"Trend" ]]};
  self.service.genres =
      @[ [[MDBGenre alloc] initWithGenreID:28 name:@"Action"], [[MDBGenre alloc] initWithGenreID:35 name:@"Comedy"] ];
  MDBExploreViewModel *viewModel = [self exploreViewModel];
  [viewModel loadIfNeeded];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    MDBExploreBrowseContent *content = viewModel.browseState.value.content;
    return content.trendingItems.count == 1 && content.genreShortcuts.count == 2;
  }));
  XCTAssertEqual(viewModel.mode.value.integerValue, MDBExploreModeBrowse);
}

- (void)testSearchIsDebouncedToTheLastQuery {
  self.service.searchPages = @{@"maze" : [MDBStubMovieService pageWithTitles:@[ @"Maze Runner" ]]};
  MDBExploreViewModel *viewModel = [self exploreViewModel];

  [viewModel updateQuery:@"m"];
  [viewModel updateQuery:@"ma"];
  [viewModel updateQuery:@"maze"];
  XCTAssertEqual(viewModel.mode.value.integerValue, MDBExploreModeSearch);
  XCTAssertTrue(viewModel.searchState.value.isLoading, @"The spinner shows while the debounce waits");

  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.searchState.value.phase == MDBLoadStateLoaded;
  }));
  XCTAssertEqualObjects(self.service.searchedQueries, @[ @"maze" ], @"Only the final keystroke should reach the API");
  MDBPagedItems *items = viewModel.searchState.value.content;
  XCTAssertEqual(items.items.count, 1u);
  XCTAssertEqualObjects([viewModel resultsSummaryForItems:items], @"1 result for ‘maze’");
}

- (void)testSubmitSkipsTheDebounceAndDoesNotSearchTwice {
  self.service.searchPages = @{@"dune" : [MDBStubMovieService pageWithTitles:@[ @"Dune" ]]};
  MDBExploreViewModel *viewModel = [self exploreViewModel];
  [viewModel updateQuery:@"dune"];
  [viewModel submitQuery];
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
  XCTAssertEqualObjects(self.service.searchedQueries, @[ @"dune" ]);
}

- (void)testStaleSearchResponseIsIgnored {
  self.service.searchDelay = 0.2;
  self.service.searchPages = @{
    @"old" : [MDBStubMovieService pageWithTitles:@[ @"Old Result" ]],
    @"new" : [MDBStubMovieService pageWithTitles:@[ @"New Result" ]],
  };
  MDBExploreViewModel *viewModel = [self exploreViewModel];
  [viewModel updateQuery:@"old"];
  [viewModel submitQuery];
  [viewModel updateQuery:@"new"];
  [viewModel submitQuery];

  MDBWaitUntil(^BOOL {
    return viewModel.searchState.value.phase == MDBLoadStateLoaded;
  });
  // Give the slower "old" response time to arrive and be thrown away.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
  XCTAssertEqualObjects(viewModel.searchState.value.content.items.firstObject.title, @"New Result");
}

- (void)testEmptyQueryGoesBackToBrowse {
  MDBExploreViewModel *viewModel = [self exploreViewModel];
  [viewModel updateQuery:@"something"];
  [viewModel updateQuery:@"   "];
  XCTAssertEqual(viewModel.mode.value.integerValue, MDBExploreModeBrowse);
  XCTAssertEqual(viewModel.searchState.value.phase, MDBLoadStateIdle);
}

- (void)testSearchWithoutMatchesIsEmptyState {
  MDBExploreViewModel *viewModel = [self exploreViewModel];
  [viewModel updateQuery:@"zzzz"];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.searchState.value.phase == MDBLoadStateEmpty;
  }));
}

@end
