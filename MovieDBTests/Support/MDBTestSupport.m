//
//  MDBTestSupport.m
//  MovieDBTests
//

#import "MDBTestSupport.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBPage.h"

@interface MDBFixtureAnchor : NSObject
@end
@implementation MDBFixtureAnchor
@end

id MDBLoadFixture(NSString *name) {
    NSBundle *bundle = [NSBundle bundleForClass:[MDBFixtureAnchor class]];
    NSURL *url = [bundle URLForResource:name withExtension:@"json"];
    NSData *data = url ? [NSData dataWithContentsOfURL:url] : nil;
    NSCAssert(data != nil, @"Missing fixture %@", name);
    id json = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    return json ?: @{};
}

NSURL *MDBTestURL(NSString *string) {
    NSURL *url = [NSURL URLWithString:string];
    NSCAssert(url != nil, @"Bad test URL %@", string);
    return url ?: [NSURL fileURLWithPath:@"/"];
}

@implementation MDBStubCancellable

- (void)cancel {
    _cancelled = YES;
}

@end

@interface MDBStubMovieService ()
@property (nonatomic, readwrite) NSUInteger listRequestCount;
@end

@implementation MDBStubMovieService

- (instancetype)init {
    self = [super init];
    if (self) {
        _listPages = @{};
        _genres = @[];
        _searchPages = @{};
        _searchedQueries = [NSMutableArray array];
    }
    return self;
}

+ (MDBPage<MDBMovie *> *)pageWithTitles:(NSArray<NSString *> *)titles {
    NSMutableArray<MDBMovie *> *movies = [NSMutableArray array];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
        [movies addObject:[[MDBMovie alloc] initWithMovieID:(NSInteger)index + 1
                                                      title:title
                                                   overview:nil
                                                 posterPath:@"/poster.jpg"
                                               backdropPath:@"/backdrop.jpg"
                                                releaseDate:nil
                                                voteAverage:7.5
                                                  voteCount:100
                                                 popularity:1
                                                   genreIDs:@[@28]]];
    }];
    return [[MDBPage alloc] initWithPage:1 totalPages:1 totalResults:(NSInteger)movies.count results:movies];
}

- (void)answer:(dispatch_block_t)block after:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
    self.listRequestCount += 1;
    MDBPage<MDBMovie *> *result = self.listError ? nil : self.listPages[@(kind)];
    NSError *error = self.listError;
    [self answer:^{ completion(result, error); } after:0];
    return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)query page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
    [self.searchedQueries addObject:query];
    MDBPage<MDBMovie *> *result = self.searchPages[query] ?: [[MDBPage alloc] initWithPage:1 totalPages:1 totalResults:0 results:@[]];
    [self answer:^{ completion(result, nil); } after:self.searchDelay];
    return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion {
    return [self fetchMovieList:MDBMovieListKindPopular page:page completion:completion];
}

- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion {
    NSArray<MDBGenre *> *genres = self.genres;
    [self answer:^{ completion(genres, nil); } after:0];
    return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion {
    [self answer:^{ completion(nil, [NSError errorWithDomain:@"test" code:1 userInfo:nil]); } after:0];
    return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion {
    [self answer:^{ completion(nil, [NSError errorWithDomain:@"test" code:1 userInfo:nil]); } after:0];
    return [[MDBStubCancellable alloc] init];
}

- (NSArray<NSString *> *)genreNamesForIDs:(NSArray<NSNumber *> *)genreIDs {
    return [genreIDs containsObject:@28] ? @[@"Action"] : @[];
}

@end
