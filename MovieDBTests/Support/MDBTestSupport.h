//
//  MDBTestSupport.h
//  MovieDBTests
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBMovie;

NS_ASSUME_NONNULL_BEGIN

/// Loads a JSON file from MovieDBTests/Fixtures.
FOUNDATION_EXPORT id MDBLoadFixture(NSString *name);
/// NSURL from a string the test knows is valid.
FOUNDATION_EXPORT NSURL *MDBTestURL(NSString *string);

@interface MDBStubCancellable : NSObject <MDBCancellable>
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
@end

/// In-memory MDBMovieService. Each method records the call and answers with whatever
/// result or error the test configured, on the main queue like the real client.
@interface MDBStubMovieService : NSObject <MDBMovieService>

@property (nonatomic, copy) NSDictionary<NSNumber *, MDBPage<MDBMovie *> *> *listPages;
@property (nonatomic, nullable) NSError *listError;
@property (nonatomic, copy) NSArray<MDBGenre *> *genres;
/// Search results keyed by query text.
@property (nonatomic, copy) NSDictionary<NSString *, MDBPage<MDBMovie *> *> *searchPages;
/// Delay before search answers, used to check that stale responses are ignored.
@property (nonatomic) NSTimeInterval searchDelay;

@property (nonatomic, readonly) NSMutableArray<NSString *> *searchedQueries;
@property (nonatomic, readonly) NSUInteger listRequestCount;

+ (MDBPage<MDBMovie *> *)pageWithTitles:(NSArray<NSString *> *)titles;

@end

NS_ASSUME_NONNULL_END
