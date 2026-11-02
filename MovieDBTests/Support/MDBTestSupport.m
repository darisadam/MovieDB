//
//  MDBTestSupport.m
//  MovieDBTests
//

#import "MDBTestSupport.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBMovieDetail.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBPerson.h"

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

MDBMovie *MDBTestMovie(NSInteger movieID, NSString *title) {
  return [[MDBMovie alloc] initWithMovieID:movieID title:title overview:@"Overview" posterPath:@"/poster.jpg"
                              backdropPath:@"/backdrop.jpg"
                               releaseDate:[NSDate dateWithTimeIntervalSince1970:1500000000]
                               voteAverage:7.5
                                 voteCount:100
                                popularity:1
                                  genreIDs:@[ @28 ]];
}

BOOL MDBWaitUntil(BOOL (^condition)(void)) {
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
  while (!condition() && [deadline timeIntervalSinceNow] > 0) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
  }
  return condition();
}

NSUserDefaults *MDBTestDefaults(NSString *suiteName) {
  NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
  NSCAssert(defaults != nil, @"Could not create defaults suite %@", suiteName);
  return defaults ?: [NSUserDefaults standardUserDefaults];
}

static void MDBAnswer(NSTimeInterval delay, dispatch_block_t block) {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

@implementation MDBStubCancellable

- (void)cancel {
  _cancelled = YES;
}

@end

@interface MDBStubMovieService ()
@property (nonatomic, readwrite) NSUInteger listRequestCount;
@property (nonatomic, readwrite) NSUInteger discoverRequestCount;
@property (nonatomic, readwrite) MDBDiscoverSort lastSort;
@end

@implementation MDBStubMovieService

- (instancetype)init {
  self = [super init];
  if (self) {
    _listPages = @{};
    _pagesByNumber = @{};
    _genres = @[];
    _searchPages = @{};
    _searchedQueries = [NSMutableArray array];
    _requestedPages = [NSMutableArray array];
    _genreNamesSubject = [[MDBSubject alloc] initWithValue:@{@28 : @"Action"}];
  }
  return self;
}

+ (MDBPage<MDBMovie *> *)pageWithTitles:(NSArray<NSString *> *)titles {
  NSMutableArray<MDBMovie *> *movies = [NSMutableArray array];
  [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
    [movies addObject:MDBTestMovie((NSInteger)index + 1, title)];
  }];
  return [[MDBPage alloc] initWithPage:1 totalPages:1 totalResults:(NSInteger)movies.count results:movies];
}

+ (MDBPage<MDBMovie *> *)pageNumber:(NSInteger)page of:(NSInteger)totalPages firstID:(NSInteger)firstID count:(NSInteger)count {
  NSMutableArray<MDBMovie *> *movies = [NSMutableArray array];
  for (NSInteger index = 0; index < count; index++) {
    NSInteger movieID = firstID + index;
    [movies addObject:MDBTestMovie(movieID, [NSString stringWithFormat:@"Movie %ld", (long)movieID])];
  }
  return [[MDBPage alloc] initWithPage:page totalPages:totalPages totalResults:totalPages * count results:movies];
}

- (MDBObservable<NSDictionary<NSNumber *, NSString *> *> *)genreNames {
  return self.genreNamesSubject;
}

- (id<MDBCancellable>)answerPage:(NSInteger)page
                        fallback:(nullable MDBPage<MDBMovie *> *)fallback
                      completion:(MDBMoviePageCompletion)completion {
  [self.requestedPages addObject:@(page)];
  MDBPage<MDBMovie *> *result = self.listError ? nil : (self.pagesByNumber[@(page)] ?: fallback);
  NSError *error = self.listError;
  MDBAnswer(0, ^{
    completion(result, error);
  });
  return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
  self.listRequestCount += 1;
  return [self answerPage:page fallback:self.listPages[@(kind)] completion:completion];
}

- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion {
  self.discoverRequestCount += 1;
  self.lastSort = sort;
  return [self answerPage:page fallback:self.listPages[@(MDBMovieListKindPopular)] completion:completion];
}

- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)query page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
  [self.searchedQueries addObject:query];
  MDBPage<MDBMovie *> *result =
      self.searchPages[query] ?: [[MDBPage alloc] initWithPage:1 totalPages:1 totalResults:0 results:@[]];
  MDBAnswer(self.searchDelay, ^{
    completion(result, nil);
  });
  return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion {
  NSArray<MDBGenre *> *genres = self.genres;
  MDBAnswer(0, ^{
    completion(genres, nil);
  });
  return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion {
  MDBMovieDetail *detail = self.detail;
  NSError *error = detail ? nil : (self.detailError ?: [NSError errorWithDomain:@"test" code:1 userInfo:nil]);
  MDBAnswer(0, ^{
    completion(detail, error);
  });
  return [[MDBStubCancellable alloc] init];
}

- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion {
  MDBPerson *person = self.person;
  NSError *error = person ? nil : [NSError errorWithDomain:@"test" code:1 userInfo:nil];
  MDBAnswer(0, ^{
    completion(person, error);
  });
  return [[MDBStubCancellable alloc] init];
}

@end

@interface MDBStubFavoritesStore ()
@property (nonatomic, readonly) MDBSubject<NSArray<MDBFavoriteMovie *> *> *subject;
@property (nonatomic, readwrite) NSUInteger removeAllCount;
@end

@implementation MDBStubFavoritesStore

- (instancetype)init {
  self = [super init];
  if (self) {
    _subject = [[MDBSubject alloc] initWithValue:@[]];
  }
  return self;
}

- (MDBObservable<NSArray<MDBFavoriteMovie *> *> *)favorites {
  return self.subject;
}

- (BOOL)isFavoriteMovieID:(NSInteger)movieID {
  for (MDBFavoriteMovie *favorite in self.subject.value) {
    if (favorite.movieID == movieID) {
      return YES;
    }
  }
  return NO;
}

- (void)finish:(nullable MDBFavoritesCompletion)completion change:(void (^)(void))change {
  NSError *error = self.nextError;
  self.nextError = nil;
  MDBAnswer(0, ^{
    if (!error) {
      change();
    }
    if (completion) {
      completion(error);
    }
  });
}

- (void)addFavoriteMovie:(MDBMovie *)movie
              genreNames:(NSArray<NSString *> *)genreNames
              completion:(nullable MDBFavoritesCompletion)completion {
  MDBSubject<NSArray<MDBFavoriteMovie *> *> *subject = self.subject;
  [self finish:completion change:^{
    MDBFavoriteMovie *favorite = [[MDBFavoriteMovie alloc] initWithMovieID:movie.movieID title:movie.title overview:movie.overview
                                                                posterPath:movie.posterPath
                                                               releaseDate:movie.releaseDate
                                                               voteAverage:movie.voteAverage
                                                                 voteCount:movie.voteCount
                                                                genreNames:genreNames
                                                                   addedAt:[NSDate date]];
    NSArray<MDBFavoriteMovie *> *current = subject.value ?: @[];
    [subject send:[@[ favorite ] arrayByAddingObjectsFromArray:current]];
  }];
}

- (void)removeFavoriteWithMovieID:(NSInteger)movieID completion:(nullable MDBFavoritesCompletion)completion {
  MDBSubject<NSArray<MDBFavoriteMovie *> *> *subject = self.subject;
  [self finish:completion change:^{
    NSMutableArray<MDBFavoriteMovie *> *kept = [NSMutableArray array];
    for (MDBFavoriteMovie *favorite in subject.value) {
      if (favorite.movieID != movieID) {
        [kept addObject:favorite];
      }
    }
    [subject send:[kept copy]];
  }];
}

- (void)removeAllFavoritesWithCompletion:(nullable MDBFavoritesCompletion)completion {
  self.removeAllCount += 1;
  MDBSubject<NSArray<MDBFavoriteMovie *> *> *subject = self.subject;
  [self finish:completion change:^{
    [subject send:@[]];
  }];
}

@end
