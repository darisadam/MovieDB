//
//  MDBPreferencesAndCellModelTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBFavoritesStore.h"
#import "MDBImageURLBuilder.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPreferences.h"
#import "MDBTestSupport.h"

@interface MDBPreferencesAndCellModelTests : XCTestCase
@property (nonatomic) NSUserDefaults *defaults;
@property (nonatomic, copy) NSString *suiteName;
@end

@implementation MDBPreferencesAndCellModelTests

- (void)setUp {
  [super setUp];
  self.suiteName = [NSString stringWithFormat:@"MovieDBTests.%@", [NSUUID UUID].UUIDString];
  self.defaults = [[NSUserDefaults alloc] initWithSuiteName:self.suiteName];
}

- (void)tearDown {
  [self.defaults removePersistentDomainForName:self.suiteName];
  [super tearDown];
}

#pragma mark - Preferences

- (void)testDefaultsToEnglish {
  MDBPreferences *preferences = [[MDBPreferences alloc] initWithUserDefaults:self.defaults];
  XCTAssertEqualObjects(preferences.languageCode, @"en-US");
  XCTAssertEqualObjects(preferences.current.value.language.title, @"English");
  XCTAssertNotNil(preferences.current.value.region);
}

- (void)testUnknownStoredValuesFallBack {
  [self.defaults setObject:@"xx-XX" forKey:@"preferences.language"];
  [self.defaults setObject:@"ZZ" forKey:@"preferences.region"];
  MDBPreferences *preferences = [[MDBPreferences alloc] initWithUserDefaults:self.defaults];
  XCTAssertEqualObjects(preferences.languageCode, @"en-US");
  XCTAssertNotEqualObjects(preferences.regionCode, @"ZZ");
}

- (void)testChangesArePublishedOnce {
  MDBPreferences *preferences = [[MDBPreferences alloc] initWithUserDefaults:self.defaults];
  NSMutableArray<MDBPreferenceSnapshot *> *changes = [NSMutableArray array];
  id<MDBDisposable> subscription = [[preferences.current skip:1] subscribe:^(MDBPreferenceSnapshot *snapshot) {
    [changes addObject:snapshot];
  }];
  // Japan, because the simulator's own region may already be Indonesia or the US.
  preferences.regionCode = @"JP";
  preferences.regionCode = @"JP";
  preferences.languageCode = @"not-a-language";
  XCTAssertEqual(changes.count, 1u);
  XCTAssertEqualObjects(changes.firstObject.region.code, @"JP");
  XCTAssertEqualObjects(changes.firstObject.region.title, @"Japan");
  [subscription dispose];
}

#pragma mark - Cell model

- (MDBImageURLBuilder *)imageURLs {
  return [[MDBImageURLBuilder alloc] initWithBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
}

- (void)testCellModelFormatsMovieText {
  MDBMovie *movie = MDBTestMovie(1, @"Green Book");
  MDBMovieCellModel *model =
      [MDBMovieCellModel modelsWithMovies:@[ movie ] genreNames:@{@28 : @"Action"} imageURLs:[self imageURLs]].firstObject;
  XCTAssertEqualObjects(model.title, @"Green Book");
  XCTAssertEqualObjects(model.yearText, @"2017");
  XCTAssertEqualObjects(model.metaText, @"2017 · Action");
  XCTAssertEqualObjects(model.ratingText, @"7.5");
  XCTAssertEqualObjects(model.votesText, @"(100 votes)");
  XCTAssertEqualObjects(model.posterURL.absoluteString, @"https://image.tmdb.org/t/p/w342/poster.jpg");
  XCTAssertEqualObjects(model.smallPosterURL.absoluteString, @"https://image.tmdb.org/t/p/w185/poster.jpg");
  XCTAssertEqualObjects([model accessibilityLabelText], @"Green Book, 2017, rated 7.5");
}

- (void)testCellModelWithoutVotesHasNoRating {
  MDBMovie *movie = [[MDBMovie alloc] initWithMovieID:2 title:@"Coming Soon" overview:nil posterPath:nil backdropPath:nil
                                          releaseDate:nil
                                          voteAverage:0
                                            voteCount:0
                                           popularity:0
                                             genreIDs:nil];
  MDBMovieCellModel *model = [MDBMovieCellModel modelWithMovie:movie genreNames:@[] imageURLs:[self imageURLs]];
  XCTAssertEqual(model.rating, 0);
  XCTAssertEqualObjects(model.votesText, @"");
  XCTAssertNil(model.posterURL);
  XCTAssertEqualObjects([model accessibilityLabelText], @"Coming Soon");
}

- (void)testCellModelFromFavoriteKeepsGenres {
  MDBFavoriteMovie *favorite = [[MDBFavoriteMovie alloc] initWithMovieID:9 title:@"Coco" overview:nil posterPath:@"/coco.jpg"
                                                             releaseDate:nil
                                                             voteAverage:8.2
                                                               voteCount:1
                                                              genreNames:@[ @"Animation", @"Family" ]
                                                                 addedAt:[NSDate date]];
  MDBMovieCellModel *model = [MDBMovieCellModel modelWithFavorite:favorite imageURLs:[self imageURLs]];
  XCTAssertEqualObjects(model.metaText, @"Animation, Family");
  XCTAssertEqualObjects(model.votesText, @"(1 vote)");
  XCTAssertEqual(model.movie.movieID, 9);
}

@end
