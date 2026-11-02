//
//  MDBScreenViewModelTests.m
//  MovieDBTests
//
//  Detail, Person, See All and Genre, Favorites and Menu.
//

#import <XCTest/XCTest.h>
#import "MDBCastCell.h"
#import "MDBFavoritesViewModel.h"
#import "MDBFormatting.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBMenuViewModel.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetail.h"
#import "MDBMovieDetailViewModel.h"
#import "MDBMovieListViewModel.h"
#import "MDBObservable.h"
#import "MDBPagedItems.h"
#import "MDBPerson.h"
#import "MDBPersonViewModel.h"
#import "MDBPreferences.h"
#import "MDBScreenState.h"
#import "MDBTestSupport.h"

@interface MDBScreenViewModelTests : XCTestCase
@property (nonatomic) MDBStubMovieService *service;
@property (nonatomic) MDBStubFavoritesStore *favorites;
@property (nonatomic) MDBImageURLBuilder *imageURLs;
@end

@implementation MDBScreenViewModelTests

- (void)setUp {
  [super setUp];
  self.service = [[MDBStubMovieService alloc] init];
  self.favorites = [[MDBStubFavoritesStore alloc] init];
  self.imageURLs = [[MDBImageURLBuilder alloc] initWithBaseURL:MDBTestURL(@"https://image.tmdb.org/t/p/")];
}

#pragma mark - Movie detail

- (MDBMovieDetailViewModel *)detailViewModel {
  return [[MDBMovieDetailViewModel alloc] initWithMovieID:291805 seedMovie:MDBTestMovie(291805, @"Seed Title")
                                                 services:self.service
                                           favoritesStore:self.favorites
                                                imageURLs:self.imageURLs];
}

- (void)testDetailShowsSeedWhileLoadingThenFullContent {
  self.service.detail = [[MDBMovieDetail alloc] initWithJSON:MDBLoadFixture(@"movie_detail")];
  MDBMovieDetailViewModel *viewModel = [self detailViewModel];
  XCTAssertEqualObjects(viewModel.state.value.content.title, @"Seed Title");
  XCTAssertFalse(viewModel.state.value.content.isComplete);

  [viewModel load];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  MDBMovieDetailContent *content = viewModel.state.value.content;
  XCTAssertEqualObjects(content.title, @"Now You See Me 2");
  XCTAssertEqualObjects(content.metaText, @"2016  ·  2h 9m");
  XCTAssertEqualObjects(content.ratingText, @"6.8");
  XCTAssertEqualObjects(content.genreNames, (@[ @"Action", @"Comedy", @"Thriller" ]));
  XCTAssertEqualObjects([content.facts valueForKey:@"title"], (@[ @"Release", @"Language", @"Budget" ]));
  XCTAssertEqualObjects(content.cast.firstObject.name, @"Jesse Eisenberg");
  XCTAssertTrue(content.hasTrailer);
  XCTAssertEqual(content.recommendations.count, 2u);
  XCTAssertEqualObjects(viewModel.shareURL.absoluteString, @"https://www.themoviedb.org/movie/291805");
}

- (void)testDetailFailureKeepsSeedContent {
  MDBMovieDetailViewModel *viewModel = [self detailViewModel];
  [viewModel load];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateFailed;
  }));
  XCTAssertEqualObjects(viewModel.state.value.content.title, @"Seed Title");
  XCTAssertNotNil(viewModel.state.value.error);
}

- (void)testFavoriteToggleFollowsTheStore {
  MDBMovieDetailViewModel *viewModel = [self detailViewModel];
  XCTAssertFalse(viewModel.isFavorite.value.boolValue);
  [viewModel toggleFavorite];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.isFavorite.value.boolValue;
  }));
  [viewModel toggleFavorite];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return !viewModel.isFavorite.value.boolValue;
  }));
}

- (void)testFavoriteStaysOffWhenSavingFails {
  self.favorites.nextError = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
  MDBMovieDetailViewModel *viewModel = [self detailViewModel];
  [viewModel toggleFavorite];
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  XCTAssertFalse(viewModel.isFavorite.value.boolValue);
}

#pragma mark - Person

- (void)testPersonContentIncludesAgeAndFilmography {
  self.service.person = [[MDBPerson alloc] initWithJSON:MDBLoadFixture(@"person")];
  MDBPersonViewModel *viewModel = [[MDBPersonViewModel alloc] initWithPersonID:10980 name:@"Daniel" services:self.service
                                                                     imageURLs:self.imageURLs];
  viewModel.now = (NSDate *_Nonnull)[MDBFormatting dateFromTMDBString:@"2026-11-02"];
  XCTAssertEqualObjects(viewModel.state.value.content.name, @"Daniel", @"Placeholder uses the name we were opened with");

  [viewModel load];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  MDBPersonContent *content = viewModel.state.value.content;
  XCTAssertEqualObjects(content.name, @"Daniel Radcliffe");
  XCTAssertEqualObjects(content.departmentText, @"Acting");
  XCTAssertTrue([content.facts.firstObject.value hasSuffix:@"(37)"]);
  XCTAssertEqual(content.filmography.count, 4u);
  XCTAssertEqualObjects(content.filmography.firstObject.roleText, @"as Manny");
  XCTAssertEqualObjects(content.filmography.lastObject.yearText, @"TBA");
  XCTAssertEqualObjects(content.knownFor.firstObject.title, @"Harry Potter and the Prisoner of Azkaban");
}

#pragma mark - See All and Genre

- (void)testListLoadsAndSortsGenreResults {
  self.service.listPages = @{@(MDBMovieListKindPopular) : [MDBStubMovieService pageWithTitles:@[ @"A", @"B" ]]};
  MDBGenre *action = [[MDBGenre alloc] initWithGenreID:28 name:@"Action"];
  MDBMovieListViewModel *viewModel = [[MDBMovieListViewModel alloc] initWithGenre:action services:self.service
                                                                        imageURLs:self.imageURLs];
  XCTAssertEqualObjects(viewModel.title, @"Action");
  XCTAssertTrue(viewModel.showsSortOptions);

  [viewModel loadFirstPage];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  XCTAssertEqual(viewModel.state.value.content.items.count, 2u);

  [viewModel selectSortAtIndex:MDBDiscoverSortRating];
  XCTAssertEqual(self.service.lastSort, MDBDiscoverSortRating);
  XCTAssertEqual(self.service.discoverRequestCount, 2u);
  [viewModel selectSortAtIndex:MDBDiscoverSortRating];
  XCTAssertEqual(self.service.discoverRequestCount, 2u, @"Same sort again does nothing");
}

- (void)testSeeAllUsesTheListEndpoint {
  self.service.listPages = @{@(MDBMovieListKindTopRated) : [MDBStubMovieService pageWithTitles:@[ @"A" ]]};
  MDBMovieListViewModel *viewModel = [[MDBMovieListViewModel alloc] initWithListKind:MDBMovieListKindTopRated
                                                                            services:self.service
                                                                           imageURLs:self.imageURLs];
  XCTAssertEqualObjects(viewModel.title, @"Top Rated");
  XCTAssertFalse(viewModel.showsSortOptions);
  [viewModel loadFirstPage];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  XCTAssertEqual(self.service.discoverRequestCount, 0u);
}

#pragma mark - Favorites

- (void)testFavoritesFollowTheStore {
  MDBFavoritesViewModel *viewModel = [[MDBFavoritesViewModel alloc] initWithFavoritesStore:self.favorites
                                                                                 imageURLs:self.imageURLs];
  XCTAssertEqual(viewModel.state.value.phase, MDBLoadStateEmpty);

  [self.favorites addFavoriteMovie:MDBTestMovie(1, @"Saved") genreNames:@[ @"Drama" ] completion:nil];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateLoaded;
  }));
  XCTAssertEqualObjects(viewModel.state.value.content.firstObject.title, @"Saved");

  [viewModel removeMovieWithID:1];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.state.value.phase == MDBLoadStateEmpty;
  }));
  XCTAssertEqualObjects([MDBFavoritesViewModel summaryForCount:1], @"1 movie · saved on this device");
  XCTAssertEqualObjects([MDBFavoritesViewModel summaryForCount:4], @"4 movies · saved on this device");
}

#pragma mark - Menu

- (void)testMenuLoadsGenresAndUpdatesPreferences {
  self.service.genres = @[ [[MDBGenre alloc] initWithGenreID:28 name:@"Action"] ];
  NSString *suite = [NSString stringWithFormat:@"MovieDBTests.%@", [NSUUID UUID].UUIDString];
  NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
  MDBPreferences *preferences = [[MDBPreferences alloc] initWithUserDefaults:defaults];
  MDBMenuViewModel *viewModel = [[MDBMenuViewModel alloc] initWithGenreProvider:self.service preferences:preferences
                                                                 favoritesStore:self.favorites];
  [viewModel loadIfNeeded];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.genresState.value.phase == MDBLoadStateLoaded;
  }));
  XCTAssertEqualObjects(viewModel.genresState.value.content.firstObject.name, @"Action");

  [viewModel selectRegionCode:@"JP"];
  XCTAssertEqualObjects(viewModel.preferences.value.region.code, @"JP");
  [viewModel selectLanguageCode:@"ko-KR"];
  XCTAssertEqualObjects(viewModel.preferences.value.language.code, @"ko-KR");
  XCTAssertTrue(MDBWaitUntil(^BOOL {
                  return viewModel.genresState.value.phase == MDBLoadStateLoaded;
                }), @"A language change reloads the genre names");

  XCTAssertEqual(viewModel.favoritesCount.value.integerValue, 0);
  [self.favorites addFavoriteMovie:MDBTestMovie(1, @"Saved") genreNames:@[] completion:nil];
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return viewModel.favoritesCount.value.integerValue == 1;
  }));
  [viewModel clearFavorites];
  XCTAssertEqual(self.favorites.removeAllCount, 1u);
  [defaults removePersistentDomainForName:suite];
}

@end
