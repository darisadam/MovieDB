//
//  MDBTMDBEndpoints.m
//  MovieDB
//

#import "MDBTMDBEndpoints.h"
#import "MDBEndpoint.h"

@interface MDBTMDBEndpoints ()
@property (nonatomic, copy, readonly) NSString *language;
@property (nonatomic, copy, readonly) NSString *region;
@end

@implementation MDBTMDBEndpoints

- (instancetype)initWithLanguage:(NSString *)language region:(NSString *)region {
  self = [super init];
  if (self) {
    _language = [language copy];
    _region = [region copy];
  }
  return self;
}

- (NSMutableDictionary<NSString *, NSString *> *)queryWithPage:(NSInteger)page {
  NSMutableDictionary<NSString *, NSString *> *query = [NSMutableDictionary dictionary];
  query[@"language"] = self.language;
  if (page > 0) {
    query[@"page"] = [NSString stringWithFormat:@"%ld", (long)page];
  }
  return query;
}

- (MDBEndpoint *)movieList:(MDBMovieListKind)kind page:(NSInteger)page {
  NSMutableDictionary<NSString *, NSString *> *query = [self queryWithPage:page];
  NSString *path = @"movie/popular";
  switch (kind) {
    case MDBMovieListKindNowPlaying:
      path = @"movie/now_playing";
      query[@"region"] = self.region;
      break;
    case MDBMovieListKindPopular: path = @"movie/popular"; break;
    case MDBMovieListKindTopRated: path = @"movie/top_rated"; break;
    case MDBMovieListKindUpcoming:
      path = @"movie/upcoming";
      query[@"region"] = self.region;
      break;
    case MDBMovieListKindTrending: path = @"trending/movie/week"; break;
  }
  return [MDBEndpoint endpointWithPath:path query:query];
}

- (MDBEndpoint *)searchWithQuery:(NSString *)queryText page:(NSInteger)page {
  NSMutableDictionary<NSString *, NSString *> *query = [self queryWithPage:page];
  query[@"query"] = queryText;
  query[@"include_adult"] = @"false";
  return [MDBEndpoint endpointWithPath:@"search/movie" query:query];
}

- (MDBEndpoint *)discoverWithGenreID:(NSInteger)genreID sort:(MDBDiscoverSort)sort page:(NSInteger)page today:(NSDate *)today {
  NSMutableDictionary<NSString *, NSString *> *query = [self queryWithPage:page];
  query[@"with_genres"] = [NSString stringWithFormat:@"%ld", (long)genreID];
  query[@"include_adult"] = @"false";
  switch (sort) {
    case MDBDiscoverSortPopularity: query[@"sort_by"] = @"popularity.desc"; break;
    case MDBDiscoverSortRating:
      query[@"sort_by"] = @"vote_average.desc";
      // Without a floor the top is full of films with three votes and a perfect 10.
      query[@"vote_count.gte"] = @"300";
      break;
    case MDBDiscoverSortNewest:
      query[@"sort_by"] = @"primary_release_date.desc";
      query[@"primary_release_date.lte"] = [self.class dayStringFromDate:today];
      query[@"vote_count.gte"] = @"10";
      break;
  }
  return [MDBEndpoint endpointWithPath:@"discover/movie" query:query];
}

- (MDBEndpoint *)genres {
  return [MDBEndpoint endpointWithPath:@"genre/movie/list" query:[self queryWithPage:0]];
}

- (MDBEndpoint *)movieDetailWithID:(NSInteger)movieID {
  NSMutableDictionary<NSString *, NSString *> *query = [self queryWithPage:0];
  query[@"append_to_response"] = @"credits,videos,recommendations";
  // Trailers are often only uploaded in English, so ask for those too.
  NSString *languageOnly = [self.language componentsSeparatedByString:@"-"].firstObject ?: @"en";
  query[@"include_video_language"] = [NSString stringWithFormat:@"%@,en,null", languageOnly];
  return [MDBEndpoint endpointWithPath:[NSString stringWithFormat:@"movie/%ld", (long)movieID] query:query];
}

- (MDBEndpoint *)personWithID:(NSInteger)personID {
  NSMutableDictionary<NSString *, NSString *> *query = [self queryWithPage:0];
  query[@"append_to_response"] = @"movie_credits";
  return [MDBEndpoint endpointWithPath:[NSString stringWithFormat:@"person/%ld", (long)personID] query:query];
}

+ (NSString *)dayStringFromDate:(NSDate *)date {
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.dateFormat = @"yyyy-MM-dd";
  });
  return [formatter stringFromDate:date];
}

@end
