//
//  MDBFavoritesStoreTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBCoreDataFavoritesStore.h"
#import "MDBCoreDataStack.h"
#import "MDBMovie.h"
#import "MDBObservable.h"
#import "MDBTestSupport.h"

@interface MDBFavoritesStoreTests : XCTestCase
@property (nonatomic) MDBCoreDataFavoritesStore *store;
@end

@implementation MDBFavoritesStoreTests

- (void)setUp {
  [super setUp];
  MDBCoreDataStack *stack = [[MDBCoreDataStack alloc] initWithStoreType:MDBCoreDataStoreTypeInMemory];
  self.store = [[MDBCoreDataFavoritesStore alloc] initWithStack:stack];
}

- (NSArray<MDBFavoriteMovie *> *)saved {
  return self.store.favorites.value ?: @[];
}

- (void)addMovie:(MDBMovie *)movie {
  XCTestExpectation *saved = [self expectationWithDescription:@"saved"];
  [self.store addFavoriteMovie:movie genreNames:@[ @"Drama", @"Comedy" ] completion:^(NSError *error) {
    XCTAssertNil(error);
    [saved fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testStartsEmptyAndPublishesChanges {
  XCTAssertTrue(self.store.favorites.hasValue, @"The store reads the database right away");
  XCTAssertEqual(self.saved.count, 0u);

  __block NSUInteger emissions = 0;
  id<MDBDisposable> subscription = [[self.store.favorites skip:1] subscribe:^(id value) {
    emissions += 1;
  }];
  [self addMovie:MDBTestMovie(42, @"The Answer")];
  XCTAssertEqual(emissions, 1u);
  [subscription dispose];

  XCTAssertTrue([self.store isFavoriteMovieID:42]);
  XCTAssertFalse([self.store isFavoriteMovieID:7]);
  XCTAssertEqualObjects(self.saved.firstObject.title, @"The Answer");
  XCTAssertEqualObjects(self.saved.firstObject.genreNames, (@[ @"Drama", @"Comedy" ]));
}

- (void)testAddingTwiceKeepsOneRow {
  [self addMovie:MDBTestMovie(1, @"First title")];
  [self addMovie:MDBTestMovie(1, @"Updated title")];
  XCTAssertEqual(self.saved.count, 1u);
  XCTAssertEqualObjects(self.saved.firstObject.title, @"Updated title");
}

- (void)testNewestFavoriteComesFirst {
  [self addMovie:MDBTestMovie(1, @"Older")];
  [self addMovie:MDBTestMovie(2, @"Newer")];
  XCTAssertEqualObjects(self.saved.firstObject.title, @"Newer");
}

- (void)testRemoveAndRemoveAll {
  [self addMovie:MDBTestMovie(1, @"One")];
  [self addMovie:MDBTestMovie(2, @"Two")];

  XCTestExpectation *removed = [self expectationWithDescription:@"removed"];
  [self.store removeFavoriteWithMovieID:1 completion:^(NSError *error) {
    [removed fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertFalse([self.store isFavoriteMovieID:1]);
  XCTAssertEqual(self.saved.count, 1u);

  XCTestExpectation *cleared = [self expectationWithDescription:@"cleared"];
  [self.store removeAllFavoritesWithCompletion:^(NSError *error) {
    [cleared fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertEqual(self.saved.count, 0u);
}

- (void)testRemovingUnknownMovieIsHarmless {
  XCTestExpectation *done = [self expectationWithDescription:@"done"];
  [self.store removeFavoriteWithMovieID:12345 completion:^(NSError *error) {
    XCTAssertNil(error);
    [done fulfill];
  }];
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
