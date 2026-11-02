//
//  MDBViewModelTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBAPIError.h"
#import "MDBExploreViewModel.h"
#import "MDBGenre.h"
#import "MDBHomeViewModel.h"
#import "MDBImageURLBuilder.h"
#import "MDBMovieCellModel.h"
#import "MDBPage.h"
#import "MDBTestSupport.h"

@interface MDBViewModelTests : XCTestCase
@property (nonatomic) MDBStubMovieService *service;
@property (nonatomic) MDBImageURLBuilder *imageURLs;
@property (nonatomic) NSNotificationCenter *center;
@end

@implementation MDBViewModelTests

- (void)setUp {
    [super setUp];
    self.service = [[MDBStubMovieService alloc] init];
    self.imageURLs = [[MDBImageURLBuilder alloc] initWithBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
    self.center = [[NSNotificationCenter alloc] init];
}

- (void)waitUntil:(BOOL (^)(void))condition {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while (!condition() && [deadline timeIntervalSinceNow] > 0) {
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}

#pragma mark - Home

- (void)testHomeBuildsCarouselAndSections {
    self.service.listPages = @{
        @(MDBMovieListKindNowPlaying): [MDBStubMovieService pageWithTitles:@[@"A", @"B"]],
        @(MDBMovieListKindPopular): [MDBStubMovieService pageWithTitles:@[@"C"]],
        @(MDBMovieListKindTopRated): [MDBStubMovieService pageWithTitles:@[@"D", @"E", @"F"]],
    };
    MDBHomeViewModel *viewModel = [[MDBHomeViewModel alloc] initWithMovieService:self.service imageURLs:self.imageURLs notificationCenter:self.center];
    [viewModel loadIfNeeded];
    XCTAssertEqual(viewModel.state, MDBLoadStateLoading);

    [self waitUntil:^BOOL { return viewModel.state != MDBLoadStateLoading; }];
    XCTAssertEqual(viewModel.state, MDBLoadStateLoaded);
    XCTAssertEqual(viewModel.carouselItems.count, 2u);
    // Upcoming came back empty so it's left out instead of showing an empty row.
    XCTAssertEqual(viewModel.sections.count, 2u);
    XCTAssertEqual(viewModel.sections[1].kind, MDBMovieListKindTopRated);
    XCTAssertEqualObjects(viewModel.sections[0].items.firstObject.metaText, @"Action");
}

- (void)testHomeFailsWhenEveryListFails {
    self.service.listError = [NSError mdb_apiErrorWithCode:MDBAPIErrorOffline message:nil underlying:nil];
    MDBHomeViewModel *viewModel = [[MDBHomeViewModel alloc] initWithMovieService:self.service imageURLs:self.imageURLs notificationCenter:self.center];
    [viewModel reload];
    [self waitUntil:^BOOL { return viewModel.state != MDBLoadStateLoading; }];
    XCTAssertEqual(viewModel.state, MDBLoadStateFailed);
    XCTAssertTrue(viewModel.error.mdb_isOffline);
}

- (void)testHomeLoadIfNeededDoesNotReloadLoadedContent {
    self.service.listPages = @{@(MDBMovieListKindPopular): [MDBStubMovieService pageWithTitles:@[@"A"]]};
    MDBHomeViewModel *viewModel = [[MDBHomeViewModel alloc] initWithMovieService:self.service imageURLs:self.imageURLs notificationCenter:self.center];
    [viewModel loadIfNeeded];
    [self waitUntil:^BOOL { return viewModel.state == MDBLoadStateLoaded; }];
    NSUInteger requests = self.service.listRequestCount;
    [viewModel loadIfNeeded];
    XCTAssertEqual(self.service.listRequestCount, requests);
}

#pragma mark - Explore

- (MDBExploreViewModel *)exploreViewModel {
    return [[MDBExploreViewModel alloc] initWithMovieService:self.service
                                                   imageURLs:self.imageURLs
                                          notificationCenter:self.center
                                            debounceInterval:0.05];
}

- (void)testSearchIsDebouncedToTheLastQuery {
    self.service.searchPages = @{@"maze": [MDBStubMovieService pageWithTitles:@[@"Maze Runner"]]};
    MDBExploreViewModel *viewModel = [self exploreViewModel];

    [viewModel updateQuery:@"m"];
    [viewModel updateQuery:@"ma"];
    [viewModel updateQuery:@"maze"];
    XCTAssertEqual(viewModel.mode, MDBExploreModeSearch);
    XCTAssertEqual(viewModel.searchState, MDBLoadStateLoading);

    [self waitUntil:^BOOL { return viewModel.searchState != MDBLoadStateLoading; }];
    XCTAssertEqualObjects(self.service.searchedQueries, @[@"maze"], @"Only the final keystroke should reach the API");
    XCTAssertEqual(viewModel.results.count, 1u);
    XCTAssertEqualObjects([viewModel resultsSummary], @"1 result for ‘maze’");
}

- (void)testStaleSearchResponseIsIgnored {
    self.service.searchDelay = 0.2;
    self.service.searchPages = @{
        @"old": [MDBStubMovieService pageWithTitles:@[@"Old Result"]],
        @"new": [MDBStubMovieService pageWithTitles:@[@"New Result"]],
    };
    MDBExploreViewModel *viewModel = [self exploreViewModel];
    [viewModel updateQuery:@"old"];
    [viewModel submitQuery];
    [viewModel updateQuery:@"new"];
    [viewModel submitQuery];

    [self waitUntil:^BOOL { return viewModel.searchState == MDBLoadStateLoaded; }];
    // Give the slower "old" response time to arrive and be thrown away.
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    XCTAssertEqualObjects(viewModel.results.firstObject.title, @"New Result");
}

- (void)testEmptyQueryGoesBackToBrowse {
    MDBExploreViewModel *viewModel = [self exploreViewModel];
    [viewModel updateQuery:@"something"];
    [viewModel updateQuery:@"   "];
    XCTAssertEqual(viewModel.mode, MDBExploreModeBrowse);
    XCTAssertEqual(viewModel.results.count, 0u);
}

- (void)testSearchWithoutMatchesIsEmptyState {
    MDBExploreViewModel *viewModel = [self exploreViewModel];
    [viewModel updateQuery:@"zzzz"];
    [self waitUntil:^BOOL { return viewModel.searchState != MDBLoadStateLoading; }];
    XCTAssertEqual(viewModel.searchState, MDBLoadStateEmpty);
}

- (void)testViewModelsAreReleased {
    __weak MDBHomeViewModel *weakHome = nil;
    __weak MDBExploreViewModel *weakExplore = nil;
    @autoreleasepool {
        MDBHomeViewModel *home = [[MDBHomeViewModel alloc] initWithMovieService:self.service imageURLs:self.imageURLs notificationCenter:self.center];
        home.onChange = ^{};
        [home reload];
        MDBExploreViewModel *explore = [self exploreViewModel];
        [explore updateQuery:@"leak check"];
        weakHome = home;
        weakExplore = explore;
    }
    XCTAssertNil(weakHome, @"Home view model is retained by something, probably a block");
    XCTAssertNil(weakExplore, @"Explore view model is retained by something, probably a block");
}

@end
