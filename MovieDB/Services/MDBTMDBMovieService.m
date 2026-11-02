//
//  MDBTMDBMovieService.m
//  MovieDB
//

#import "MDBTMDBMovieService.h"
#import "MDBAPIClient.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBMovieDetail.h"
#import "MDBObservable.h"
#import "MDBPage.h"
#import "MDBPerson.h"
#import "MDBPreferences.h"
#import "MDBTMDBEndpoints.h"
#import "NSDictionary+MDBSafeJSON.h"

NSString *MDBMovieListKindTitle(MDBMovieListKind kind) {
  switch (kind) {
    case MDBMovieListKindNowPlaying: return @"Now Playing";
    case MDBMovieListKindPopular: return @"Popular";
    case MDBMovieListKindTopRated: return @"Top Rated";
    case MDBMovieListKindUpcoming: return @"Upcoming";
    case MDBMovieListKindTrending: return @"Trending this week";
  }
  return @"Movies";
}

NSString *MDBDiscoverSortTitle(MDBDiscoverSort sort) {
  switch (sort) {
    case MDBDiscoverSortPopularity: return @"Popularity";
    case MDBDiscoverSortRating: return @"Rating";
    case MDBDiscoverSortNewest: return @"Newest";
  }
  return @"Popularity";
}

NSArray<NSString *> *MDBGenreNamesForIDs(NSDictionary<NSNumber *, NSString *> *_Nullable names, NSArray<NSNumber *> *genreIDs) {
  NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:genreIDs.count];
  for (NSNumber *genreID in genreIDs) {
    NSString *name = names[genreID];
    if (name) {
      [result addObject:name];
    }
  }
  return [result copy];
}

@interface MDBTMDBMovieService ()
@property (nonatomic, readonly) MDBAPIClient *client;
@property (nonatomic, readonly) MDBPreferences *preferences;
@property (nonatomic, readonly) MDBSubject<NSDictionary<NSNumber *, NSString *> *> *genreNamesSubject;
@end

@implementation MDBTMDBMovieService

- (instancetype)initWithClient:(MDBAPIClient *)client preferences:(MDBPreferences *)preferences {
  self = [super init];
  if (self) {
    _client = client;
    _preferences = preferences;
    _genreNamesSubject = [[MDBSubject alloc] initWithValue:@{}];
  }
  return self;
}

- (MDBObservable<NSDictionary<NSNumber *, NSString *> *> *)genreNames {
  return self.genreNamesSubject;
}

/// Built per request so a region or language change applies right away.
- (MDBTMDBEndpoints *)endpoints {
  return [[MDBTMDBEndpoints alloc] initWithLanguage:self.preferences.languageCode region:self.preferences.regionCode];
}

+ (MDBAPIParser)moviePageParser {
  return ^id _Nullable(id JSON) {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
      return nil;
    }
    return [[MDBPage alloc] initWithJSON:JSON itemParser:^NSArray *(NSArray *items) {
      return [MDBMovie moviesFromJSONArray:items];
    }];
  };
}

#pragma mark - MDBMovieListProviding

- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
  return [self.client GET:[self.endpoints movieList:kind page:page] parser:[self.class moviePageParser] completion:completion];
}

- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion {
  MDBEndpoint *endpoint = [self.endpoints discoverWithGenreID:genreID sort:sort page:page today:[NSDate date]];
  return [self.client GET:endpoint parser:[self.class moviePageParser] completion:completion];
}

#pragma mark - MDBMovieSearching

- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)query page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
  return [self.client GET:[self.endpoints searchWithQuery:query page:page] parser:[self.class moviePageParser]
               completion:completion];
}

#pragma mark - MDBMovieDetailProviding

- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion {
  return [self.client GET:[self.endpoints movieDetailWithID:movieID] parser:^id _Nullable(id JSON) {
    return [JSON isKindOfClass:[NSDictionary class]] ? [[MDBMovieDetail alloc] initWithJSON:JSON] : nil;
  } completion:completion];
}

#pragma mark - MDBPersonProviding

- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion {
  return [self.client GET:[self.endpoints personWithID:personID] parser:^id _Nullable(id JSON) {
    return [JSON isKindOfClass:[NSDictionary class]] ? [[MDBPerson alloc] initWithJSON:JSON] : nil;
  } completion:completion];
}

#pragma mark - MDBGenreProviding

- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion {
  MDBSubject<NSDictionary<NSNumber *, NSString *> *> *subject = self.genreNamesSubject;
  MDBGenreListCompletion callback = [completion copy];
  return [self.client GET:[self.endpoints genres] parser:^id _Nullable(id JSON) {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
      return nil;
    }
    return [MDBGenre genresFromJSONArray:[(NSDictionary *)JSON mdb_arrayForKey:@"genres"]];
  } completion:^(id _Nullable result, NSError *_Nullable error) {
    NSArray<MDBGenre *> *genres = result;
    if (genres.count > 0) {
      NSMutableDictionary<NSNumber *, NSString *> *names = [NSMutableDictionary dictionary];
      for (MDBGenre *genre in genres) {
        names[@(genre.genreID)] = genre.name;
      }
      [subject send:[names copy]];
    }
    callback(genres, error);
  }];
}

@end
