//
//  MDBTestSupport.h
//  MovieDBTests
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "MDBFavoritesStore.h"
#import "MDBMovieService.h"

@class MDBMovie;
@class MDBMovieDetail;
@class MDBPerson;
@class MDBSubject<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

/// Loads a JSON file from MovieDBTests/Fixtures.
FOUNDATION_EXPORT id MDBLoadFixture(NSString *name);
/// NSURL from a string the test knows is valid.
FOUNDATION_EXPORT NSURL *MDBTestURL(NSString *string);
/// A movie with sensible defaults for tests.
FOUNDATION_EXPORT MDBMovie *MDBTestMovie(NSInteger movieID, NSString *title);
/// Spins the main run loop until the condition holds or a few seconds pass.
FOUNDATION_EXPORT BOOL MDBWaitUntil(BOOL (^condition)(void));
/// A throwaway defaults suite so tests never touch the real app settings.
FOUNDATION_EXPORT NSUserDefaults *MDBTestDefaults(NSString *suiteName);

@interface MDBStubCancellable : NSObject <MDBCancellable>
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
@end

/// In-memory TMDB service. It answers on the main queue like the real client and
/// records every call so tests can check what was asked for.
@interface MDBStubMovieService : NSObject <MDBMovieService>

@property (nonatomic, copy) NSDictionary<NSNumber *, MDBPage<MDBMovie *> *> *listPages;
@property (nonatomic, nullable) NSError *listError;
/// Optional pages by page number, used for paging tests. Falls back to listPages.
@property (nonatomic, copy) NSDictionary<NSNumber *, MDBPage<MDBMovie *> *> *pagesByNumber;
@property (nonatomic, copy) NSArray<MDBGenre *> *genres;
@property (nonatomic, copy) NSDictionary<NSString *, MDBPage<MDBMovie *> *> *searchPages;
@property (nonatomic) NSTimeInterval searchDelay;
@property (nonatomic, nullable) MDBMovieDetail *detail;
@property (nonatomic, nullable) MDBPerson *person;
@property (nonatomic, nullable) NSError *detailError;

@property (nonatomic, readonly) NSMutableArray<NSString *> *searchedQueries;
@property (nonatomic, readonly) NSMutableArray<NSNumber *> *requestedPages;
@property (nonatomic, readonly) NSUInteger listRequestCount;
@property (nonatomic, readonly) NSUInteger discoverRequestCount;
@property (nonatomic, readonly) MDBDiscoverSort lastSort;
@property (nonatomic, readonly) MDBSubject<NSDictionary<NSNumber *, NSString *> *> *genreNamesSubject;

+ (MDBPage<MDBMovie *> *)pageWithTitles:(NSArray<NSString *> *)titles;
+ (MDBPage<MDBMovie *> *)pageNumber:(NSInteger)page of:(NSInteger)totalPages firstID:(NSInteger)firstID count:(NSInteger)count;

@end

/// Favorites kept in an array, published like the Core Data store.
@interface MDBStubFavoritesStore : NSObject <MDBFavoritesStore>
@property (nonatomic, nullable) NSError *nextError;
@property (nonatomic, readonly) NSUInteger removeAllCount;
@end

NS_ASSUME_NONNULL_END
