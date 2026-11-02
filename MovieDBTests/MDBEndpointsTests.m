//
//  MDBEndpointsTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBEndpoint.h"
#import "MDBFormatting.h"
#import "MDBTMDBEndpoints.h"
#import "MDBTestSupport.h"

@interface MDBEndpointsTests : XCTestCase
@property (nonatomic) MDBTMDBEndpoints *endpoints;
@end

@implementation MDBEndpointsTests

- (void)setUp {
  [super setUp];
  self.endpoints = [[MDBTMDBEndpoints alloc] initWithLanguage:@"id-ID" region:@"ID"];
}

- (NSString *)URLFor:(MDBEndpoint *)endpoint {
  return [endpoint URLWithBaseURL:MDBTestURL(@"https://api.themoviedb.org/3/")].absoluteString;
}

- (void)testRegionOnlyOnRegionalLists {
  XCTAssertEqualObjects([self URLFor:[self.endpoints movieList:MDBMovieListKindNowPlaying page:1]],
                        @"https://api.themoviedb.org/3/movie/now_playing?language=id-ID&page=1&region=ID");
  XCTAssertEqualObjects([self URLFor:[self.endpoints movieList:MDBMovieListKindUpcoming page:2]],
                        @"https://api.themoviedb.org/3/movie/upcoming?language=id-ID&page=2&region=ID");
  XCTAssertEqualObjects([self URLFor:[self.endpoints movieList:MDBMovieListKindPopular page:1]],
                        @"https://api.themoviedb.org/3/movie/popular?language=id-ID&page=1");
  XCTAssertEqualObjects([self URLFor:[self.endpoints movieList:MDBMovieListKindTopRated page:1]],
                        @"https://api.themoviedb.org/3/movie/top_rated?language=id-ID&page=1");
  XCTAssertEqualObjects([self URLFor:[self.endpoints movieList:MDBMovieListKindTrending page:1]],
                        @"https://api.themoviedb.org/3/trending/movie/week?language=id-ID&page=1");
}

- (void)testSearchExcludesAdultTitles {
  XCTAssertEqualObjects([self URLFor:[self.endpoints searchWithQuery:@"maze" page:1]],
                        @"https://api.themoviedb.org/3/search/movie?include_adult=false&language=id-ID&page=1&query=maze");
}

- (void)testDiscoverSorts {
  NSDate *today = (NSDate *_Nonnull)[MDBFormatting dateFromTMDBString:@"2026-11-02"];
  NSString *popular = [self URLFor:[self.endpoints discoverWithGenreID:28 sort:MDBDiscoverSortPopularity page:1 today:today]];
  XCTAssertTrue([popular containsString:@"sort_by=popularity.desc"]);
  XCTAssertTrue([popular containsString:@"with_genres=28"]);

  NSString *rating = [self URLFor:[self.endpoints discoverWithGenreID:28 sort:MDBDiscoverSortRating page:1 today:today]];
  XCTAssertTrue([rating containsString:@"sort_by=vote_average.desc"]);
  XCTAssertTrue([rating containsString:@"vote_count.gte=300"], @"Rating sort needs a vote floor");

  NSString *newest = [self URLFor:[self.endpoints discoverWithGenreID:28 sort:MDBDiscoverSortNewest page:1 today:today]];
  XCTAssertTrue([newest containsString:@"primary_release_date.lte=2026-11-02"], @"Newest must not list unreleased films");
}

- (void)testDetailAndPersonAppendExtras {
  NSString *detail = [self URLFor:[self.endpoints movieDetailWithID:291805]];
  // Commas are legal in a query, so NSURLComponents leaves them as they are.
  XCTAssertEqualObjects(detail, @"https://api.themoviedb.org/3/movie/291805?append_to_response=credits,videos,recommendations"
                                @"&include_video_language=id,en,null&language=id-ID");
  XCTAssertEqualObjects([self URLFor:[self.endpoints personWithID:10980]],
                        @"https://api.themoviedb.org/3/person/10980?append_to_response=movie_credits&language=id-ID");
  XCTAssertEqualObjects([self URLFor:[self.endpoints genres]], @"https://api.themoviedb.org/3/genre/movie/list?language=id-ID");
}

@end
