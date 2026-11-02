//
//  MDBMovieDetail.m
//  MovieDB
//

#import "MDBMovieDetail.h"
#import "MDBCastMember.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBVideo.h"
#import "NSDictionary+MDBSafeJSON.h"

static const NSUInteger MDBDetailCastLimit = 20;
static const NSUInteger MDBDetailRecommendationLimit = 12;

@implementation MDBMovieDetail

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
  MDBMovie *movie = [[MDBMovie alloc] initWithJSON:JSON];
  if (!movie) {
    return nil;
  }
  self = [super init];
  if (self) {
    _movie = movie;
    _runtimeMinutes = [JSON mdb_integerForKey:@"runtime" defaultValue:0];
    _tagline = [[JSON mdb_nonEmptyStringForKey:@"tagline"] copy];
    _status = [[JSON mdb_nonEmptyStringForKey:@"status"] copy];
    _budget = [JSON mdb_longLongForKey:@"budget" defaultValue:0];
    _revenue = [JSON mdb_longLongForKey:@"revenue" defaultValue:0];
    _genres = [MDBGenre genresFromJSONArray:[JSON mdb_arrayForKey:@"genres"]];
    _originalLanguageName = [[self.class languageNameFromJSON:JSON] copy];

    NSDictionary *credits = [JSON mdb_dictionaryForKey:@"credits"];
    NSMutableArray<MDBCastMember *> *cast = [NSMutableArray array];
    for (NSDictionary *item in [credits mdb_dictionaryArrayForKey:@"cast"]) {
      MDBCastMember *member = [[MDBCastMember alloc] initWithJSON:item];
      if (member) {
        [cast addObject:member];
      }
    }
    [cast sortUsingComparator:^NSComparisonResult(MDBCastMember *lhs, MDBCastMember *rhs) {
      if (lhs.order == rhs.order) {
        return NSOrderedSame;
      }
      return lhs.order < rhs.order ? NSOrderedAscending : NSOrderedDescending;
    }];
    _cast = [[cast subarrayWithRange:NSMakeRange(0, MIN(cast.count, MDBDetailCastLimit))] copy];

    NSDictionary *videos = [JSON mdb_dictionaryForKey:@"videos"];
    _videos = [MDBVideo playableVideosFromJSONArray:[videos mdb_arrayForKey:@"results"]];

    NSDictionary *recommendations = [JSON mdb_dictionaryForKey:@"recommendations"];
    NSArray<MDBMovie *> *similar = [MDBMovie moviesFromJSONArray:[recommendations mdb_arrayForKey:@"results"]];
    _recommendations = [[similar subarrayWithRange:NSMakeRange(0, MIN(similar.count, MDBDetailRecommendationLimit))] copy];
  }
  return self;
}

+ (nullable NSString *)languageNameFromJSON:(NSDictionary *)JSON {
  NSString *code = [JSON mdb_nonEmptyStringForKey:@"original_language"];
  for (NSDictionary *language in [JSON mdb_dictionaryArrayForKey:@"spoken_languages"]) {
    if ([[language mdb_stringForKey:@"iso_639_1"] isEqualToString:code]) {
      NSString *english = [language mdb_nonEmptyStringForKey:@"english_name"];
      if (english) {
        return english;
      }
    }
  }
  if (!code) {
    return nil;
  }
  NSLocale *english = [NSLocale localeWithLocaleIdentifier:@"en"];
  return [english displayNameForKey:NSLocaleLanguageCode value:code] ?: code.uppercaseString;
}

- (nullable MDBVideo *)preferredTrailer {
  return self.videos.firstObject;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<MDBMovieDetail %@ runtime %ld, %lu cast, %lu videos, %lu similar>", self.movie,
                                    (long)self.runtimeMinutes, (unsigned long)self.cast.count, (unsigned long)self.videos.count,
                                    (unsigned long)self.recommendations.count];
}

@end
