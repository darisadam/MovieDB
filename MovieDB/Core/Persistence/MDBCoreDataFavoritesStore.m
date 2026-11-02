//
//  MDBCoreDataFavoritesStore.m
//  MovieDB
//

#import "MDBCoreDataFavoritesStore.h"
#import "MDBCoreDataStack.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBObservable.h"

// Genre names are stored as one string. TMDB genre names never contain a pipe.
static NSString *const MDBGenreSeparator = @"|";

@implementation MDBFavoriteMovie

- (instancetype)initWithMovieID:(NSInteger)movieID
                          title:(NSString *)title
                       overview:(nullable NSString *)overview
                     posterPath:(nullable NSString *)posterPath
                    releaseDate:(nullable NSDate *)releaseDate
                    voteAverage:(double)voteAverage
                      voteCount:(NSInteger)voteCount
                     genreNames:(NSArray<NSString *> *)genreNames
                        addedAt:(NSDate *)addedAt {
  self = [super init];
  if (self) {
    _movieID = movieID;
    _title = [title copy];
    _overview = [overview copy];
    _posterPath = [posterPath copy];
    _releaseDate = [releaseDate copy];
    _voteAverage = voteAverage;
    _voteCount = voteCount;
    _genreNames = [genreNames copy];
    _addedAt = [addedAt copy];
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MDBFavoriteMovie class]]) {
    return NO;
  }
  MDBFavoriteMovie *other = object;
  return other.movieID == self.movieID && [other.title isEqualToString:self.title] && [other.addedAt isEqualToDate:self.addedAt];
}

- (NSUInteger)hash {
  return (NSUInteger)self.movieID;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<MDBFavoriteMovie %ld \"%@\" added %@>", (long)self.movieID, self.title, self.addedAt];
}

@end

@interface MDBCoreDataFavoritesStore ()
@property (nonatomic, readonly) MDBCoreDataStack *stack;
@property (nonatomic, readonly) MDBSubject<NSArray<MDBFavoriteMovie *> *> *subject;
@end

@implementation MDBCoreDataFavoritesStore

- (instancetype)initWithStack:(MDBCoreDataStack *)stack {
  self = [super init];
  if (self) {
    _stack = stack;
    _subject = [[MDBSubject alloc] init];
    [self refresh];
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

#pragma mark - Reading

/// Fetches from the view context and publishes the list. Main thread only.
- (void)refresh {
  MDBAssertMainThread();
  NSFetchRequest<NSManagedObject *> *request = [NSFetchRequest fetchRequestWithEntityName:MDBFavoriteEntityName];
  request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"addedAt" ascending:NO] ];
  NSError *error = nil;
  NSArray<NSManagedObject *> *objects = [self.stack.viewContext executeFetchRequest:request error:&error];
  if (!objects) {
    MDBLogError(MDBLogCategoryPersistence, @"Fetching favorites failed: %@", error);
    objects = @[];
  }
  NSMutableArray<MDBFavoriteMovie *> *favorites = [NSMutableArray arrayWithCapacity:objects.count];
  for (NSManagedObject *object in objects) {
    MDBFavoriteMovie *favorite = [MDBCoreDataFavoritesStore favoriteFromObject:object];
    if (favorite) {
      [favorites addObject:favorite];
    }
  }
  [self.subject send:[favorites copy]];
}

+ (nullable MDBFavoriteMovie *)favoriteFromObject:(NSManagedObject *)object {
  NSNumber *movieID = [object valueForKey:@"movieID"];
  NSString *title = [object valueForKey:@"title"];
  if (![movieID isKindOfClass:[NSNumber class]] || ![title isKindOfClass:[NSString class]]) {
    return nil;
  }
  NSString *genres = [object valueForKey:@"genreNames"];
  NSArray<NSString *> *genreNames = genres.length > 0 ? [genres componentsSeparatedByString:MDBGenreSeparator] : @[];
  return [[MDBFavoriteMovie alloc] initWithMovieID:movieID.integerValue title:title overview:[object valueForKey:@"overview"]
                                        posterPath:[object valueForKey:@"posterPath"]
                                       releaseDate:[object valueForKey:@"releaseDate"]
                                       voteAverage:[[object valueForKey:@"voteAverage"] doubleValue]
                                         voteCount:[[object valueForKey:@"voteCount"] integerValue]
                                        genreNames:genreNames
                                           addedAt:[object valueForKey:@"addedAt"] ?: [NSDate date]];
}

+ (nullable NSManagedObject *)objectForMovieID:(NSInteger)movieID inContext:(NSManagedObjectContext *)context {
  NSFetchRequest<NSManagedObject *> *request = [NSFetchRequest fetchRequestWithEntityName:MDBFavoriteEntityName];
  request.predicate = [NSPredicate predicateWithFormat:@"movieID == %ld", (long)movieID];
  request.fetchLimit = 1;
  return [context executeFetchRequest:request error:nil].firstObject;
}

#pragma mark - Writing

- (void)addFavoriteMovie:(MDBMovie *)movie
              genreNames:(NSArray<NSString *> *)genreNames
              completion:(nullable MDBFavoritesCompletion)completion {
  NSInteger movieID = movie.movieID;
  NSString *title = [movie.title copy];
  NSString *overview = [movie.overview copy];
  NSString *posterPath = [movie.posterPath copy];
  NSDate *releaseDate = movie.releaseDate;
  double voteAverage = movie.voteAverage;
  NSInteger voteCount = movie.voteCount;
  NSString *joinedGenres = [genreNames componentsJoinedByString:MDBGenreSeparator];

  [self performWrite:^BOOL(NSManagedObjectContext *context, NSError **error) {
    NSManagedObject *object = [MDBCoreDataFavoritesStore objectForMovieID:movieID inContext:context];
    if (!object) {
      object = [NSEntityDescription insertNewObjectForEntityForName:MDBFavoriteEntityName inManagedObjectContext:context];
      [object setValue:@(movieID) forKey:@"movieID"];
      [object setValue:[NSDate date] forKey:@"addedAt"];
    }
    [object setValue:title forKey:@"title"];
    [object setValue:overview forKey:@"overview"];
    [object setValue:posterPath forKey:@"posterPath"];
    [object setValue:releaseDate forKey:@"releaseDate"];
    [object setValue:@(voteAverage) forKey:@"voteAverage"];
    [object setValue:@(voteCount) forKey:@"voteCount"];
    [object setValue:joinedGenres forKey:@"genreNames"];
    return [context save:error];
  } logMessage:[NSString stringWithFormat:@"add %ld", (long)movieID] completion:completion];
}

- (void)removeFavoriteWithMovieID:(NSInteger)movieID completion:(nullable MDBFavoritesCompletion)completion {
  [self performWrite:^BOOL(NSManagedObjectContext *context, NSError **error) {
    NSManagedObject *object = [MDBCoreDataFavoritesStore objectForMovieID:movieID inContext:context];
    if (!object) {
      return YES;
    }
    [context deleteObject:object];
    return [context save:error];
  } logMessage:[NSString stringWithFormat:@"remove %ld", (long)movieID] completion:completion];
}

- (void)removeAllFavoritesWithCompletion:(nullable MDBFavoritesCompletion)completion {
  [self performWrite:^BOOL(NSManagedObjectContext *context, NSError **error) {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MDBFavoriteEntityName];
    request.includesPropertyValues = NO;
    NSArray<NSManagedObject *> *objects = [context executeFetchRequest:request error:error];
    if (!objects) {
      return NO;
    }
    for (NSManagedObject *object in objects) {
      [context deleteObject:object];
    }
    return [context save:error];
  } logMessage:@"remove all" completion:completion];
}

/// Runs the block on a fresh background context, then refreshes and reports back on the main queue.
- (void)performWrite:(BOOL (^)(NSManagedObjectContext *context, NSError **error))work
          logMessage:(NSString *)logMessage
          completion:(nullable MDBFavoritesCompletion)completion {
  NSManagedObjectContext *context = [self.stack newBackgroundContext];
  MDBFavoritesCompletion callback = [completion copy];
  __weak typeof(self) weakSelf = self;

  [context performBlock:^{
    NSError *error = nil;
    BOOL success = work(context, &error);
    if (success) {
      MDBLogInfo(MDBLogCategoryPersistence, @"Favorites %@", logMessage);
    } else {
      [context rollback];
      MDBLogError(MDBLogCategoryPersistence, @"Favorites %@ failed: %@", logMessage, error);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      if (success) {
        [weakSelf refresh];
      }
      if (callback) {
        callback(success ? nil : error);
      }
    });
  }];
}

@end
