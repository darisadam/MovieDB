//
//  MDBFavoritesStoreTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBCoreDataFavoritesStore.h"
#import "MDBCoreDataStack.h"
#import "MDBMovie.h"

@interface MDBFavoritesStoreTests : XCTestCase
@property (nonatomic) MDBCoreDataFavoritesStore *store;
@property (nonatomic) NSNotificationCenter *center;
@end

@implementation MDBFavoritesStoreTests

- (void)setUp {
    [super setUp];
    self.center = [[NSNotificationCenter alloc] init];
    MDBCoreDataStack *stack = [[MDBCoreDataStack alloc] initWithStoreType:MDBCoreDataStoreTypeInMemory];
    self.store = [[MDBCoreDataFavoritesStore alloc] initWithStack:stack notificationCenter:self.center];
}

- (MDBMovie *)movieWithID:(NSInteger)movieID title:(NSString *)title {
    return [[MDBMovie alloc] initWithMovieID:movieID
                                       title:title
                                    overview:@"Overview"
                                  posterPath:@"/p.jpg"
                                backdropPath:nil
                                 releaseDate:[NSDate dateWithTimeIntervalSince1970:0]
                                 voteAverage:7.1
                                   voteCount:10
                                  popularity:1
                                    genreIDs:nil];
}

- (void)addMovie:(MDBMovie *)movie {
    XCTestExpectation *saved = [self expectationWithDescription:@"saved"];
    [self.store addFavoriteMovie:movie genreNames:@[@"Drama", @"Comedy"] completion:^(NSError *error) {
        XCTAssertNil(error);
        [saved fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddAndReadBack {
    [self expectationForNotification:MDBFavoritesDidChangeNotification object:self.store notificationCenter:self.center handler:nil];
    [self addMovie:[self movieWithID:42 title:@"The Answer"]];

    XCTAssertTrue([self.store isFavoriteMovieID:42]);
    XCTAssertFalse([self.store isFavoriteMovieID:7]);
    NSArray<MDBFavoriteMovie *> *all = [self.store allFavorites];
    XCTAssertEqual(all.count, 1u);
    XCTAssertEqualObjects(all.firstObject.title, @"The Answer");
    XCTAssertEqualObjects(all.firstObject.genreNames, (@[@"Drama", @"Comedy"]));
}

- (void)testAddingTwiceKeepsOneRow {
    [self addMovie:[self movieWithID:1 title:@"First title"]];
    [self addMovie:[self movieWithID:1 title:@"Updated title"]];
    XCTAssertEqual([self.store favoritesCount], 1u);
    XCTAssertEqualObjects([self.store allFavorites].firstObject.title, @"Updated title");
}

- (void)testNewestFavoriteComesFirst {
    [self addMovie:[self movieWithID:1 title:@"Older"]];
    [self addMovie:[self movieWithID:2 title:@"Newer"]];
    XCTAssertEqualObjects([self.store allFavorites].firstObject.title, @"Newer");
}

- (void)testRemoveAndRemoveAll {
    [self addMovie:[self movieWithID:1 title:@"One"]];
    [self addMovie:[self movieWithID:2 title:@"Two"]];

    XCTestExpectation *removed = [self expectationWithDescription:@"removed"];
    [self.store removeFavoriteWithMovieID:1 completion:^(NSError *error) {
        [removed fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssertFalse([self.store isFavoriteMovieID:1]);
    XCTAssertEqual([self.store favoritesCount], 1u);

    XCTestExpectation *cleared = [self expectationWithDescription:@"cleared"];
    [self.store removeAllFavoritesWithCompletion:^(NSError *error) {
        [cleared fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
    XCTAssertEqual([self.store favoritesCount], 0u);
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
