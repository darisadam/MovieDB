//
//  MDBModelParsingTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBCastMember.h"
#import "MDBFormatting.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBMovieDetail.h"
#import "MDBPage.h"
#import "MDBPerson.h"
#import "MDBTestSupport.h"
#import "MDBVideo.h"

@interface MDBModelParsingTests : XCTestCase
@end

@implementation MDBModelParsingTests

- (void)testMoviePageDropsBrokenAndDuplicateEntries {
    MDBPage<MDBMovie *> *page = [[MDBPage alloc] initWithJSON:MDBLoadFixture(@"movie_list") itemParser:^NSArray *(NSArray *items) {
        return [MDBMovie moviesFromJSONArray:items];
    }];

    XCTAssertNotNil(page);
    XCTAssertEqual(page.page, 1);
    XCTAssertEqual(page.totalPages, 3);
    XCTAssertTrue(page.hasMore);
    // Green Book, Split, Upcoming Thing. The duplicate, the empty title and the string are skipped.
    XCTAssertEqual(page.results.count, 3u);
    XCTAssertEqualObjects(page.results[0].title, @"Green Book");
    XCTAssertEqualObjects(page.results[1].title, @"Split");
    XCTAssertNil(page.results[1].backdropPath, @"null should become nil, not NSNull");
}

- (void)testMovieFieldsAreTyped {
    MDBPage<MDBMovie *> *page = [[MDBPage alloc] initWithJSON:MDBLoadFixture(@"movie_list") itemParser:^NSArray *(NSArray *items) {
        return [MDBMovie moviesFromJSONArray:items];
    }];
    MDBMovie *greenBook = page.results[0];
    XCTAssertEqual(greenBook.movieID, 490132);
    XCTAssertEqualWithAccuracy(greenBook.voteAverage, 8.2, 0.001);
    XCTAssertEqualObjects(greenBook.genreIDs, (@[@18, @35, @36]));
    XCTAssertEqualObjects([MDBFormatting yearStringFromDate:greenBook.releaseDate], @"2018");

    MDBMovie *upcoming = page.results[2];
    XCTAssertNil(upcoming.releaseDate);
    XCTAssertEqualObjects(upcoming.genreIDs, @[], @"A string where an array belongs is ignored");
}

- (void)testPageRejectsNonPagedJSON {
    XCTAssertNil([[MDBPage alloc] initWithJSON:@{@"page": @1} itemParser:^NSArray *(NSArray *items) { return items; }]);
}

- (void)testPageCapsTotalPagesAtTMDBLimit {
    MDBPage *page = [[MDBPage alloc] initWithPage:1 totalPages:9000 totalResults:180000 results:@[]];
    XCTAssertEqual(page.totalPages, 500);
}

- (void)testMovieDetailParsesCreditsVideosAndRecommendations {
    MDBMovieDetail *detail = [[MDBMovieDetail alloc] initWithJSON:MDBLoadFixture(@"movie_detail")];
    XCTAssertNotNil(detail);
    XCTAssertEqualObjects(detail.movie.title, @"Now You See Me 2");
    XCTAssertEqual(detail.runtimeMinutes, 129);
    XCTAssertEqual(detail.budget, 90000000LL);
    XCTAssertEqualObjects(detail.originalLanguageName, @"English");
    XCTAssertEqual(detail.genres.count, 3u);

    // Sorted by billing order, the row with id 0 is dropped.
    XCTAssertEqual(detail.cast.count, 3u);
    XCTAssertEqualObjects(detail.cast.firstObject.name, @"Jesse Eisenberg");

    // YouTube only. Official trailer, then fan trailer, then teaser, then featurette.
    NSArray<NSString *> *keys = [detail.videos valueForKey:@"key"];
    XCTAssertEqualObjects(keys, (@[@"official_tr", @"fan_trailer", @"teaser_old", @"abcFeat_01"]));
    XCTAssertEqualObjects(detail.preferredTrailer.key, @"official_tr");
    XCTAssertEqualObjects(detail.preferredTrailer.watchURL.absoluteString, @"https://www.youtube.com/watch?v=official_tr");

    XCTAssertEqual(detail.recommendations.count, 2u);
}

- (void)testPersonCreditsAreDeduplicatedAndSorted {
    MDBPerson *person = [[MDBPerson alloc] initWithJSON:MDBLoadFixture(@"person")];
    XCTAssertNotNil(person);
    XCTAssertEqualObjects(person.name, @"Daniel Radcliffe");
    XCTAssertNil(person.deathday);
    XCTAssertEqual(person.filmography.count, 4u, @"The repeated Harry Potter credit only counts once");

    // Newest first, undated last.
    XCTAssertEqualObjects(person.filmography.firstObject.movie.title, @"Swiss Army Man");
    XCTAssertEqualObjects(person.filmography.lastObject.movie.title, @"Untitled Project");

    // Known For is ordered by votes.
    XCTAssertEqualObjects(person.knownFor.firstObject.movie.title, @"Harry Potter and the Prisoner of Azkaban");
    XCTAssertEqualObjects(person.knownFor.firstObject.character, @"Harry Potter");
}

- (void)testGenresSkipInvalidEntries {
    NSDictionary *json = MDBLoadFixture(@"genres");
    NSArray<MDBGenre *> *genres = [MDBGenre genresFromJSONArray:json[@"genres"]];
    XCTAssertEqual(genres.count, 4u);
    XCTAssertEqualObjects(genres.firstObject.name, @"Action");
}

- (void)testInitWithJSONRejectsWrongTypes {
    NSDictionary *wrongIDType = @{@"id": @"12", @"title": @"Wrong id type"};
    NSDictionary *nullTitle = @{@"id": @12, @"title": [NSNull null]};
    XCTAssertNil([[MDBMovie alloc] initWithJSON:wrongIDType]);
    XCTAssertNil([[MDBMovie alloc] initWithJSON:nullTitle]);
    XCTAssertNil([[MDBCastMember alloc] initWithJSON:@{@"id": @5}]);
    XCTAssertNil([[MDBVideo alloc] initWithJSON:@{@"key": @"abc"}]);
}

@end
