//
//  MDBMovie.m
//  MovieDB
//

#import "MDBMovie.h"
#import "MDBFormatting.h"
#import "NSDictionary+MDBSafeJSON.h"

@implementation MDBMovie

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSInteger movieID = [JSON mdb_integerForKey:@"id" defaultValue:0];
    NSString *title = [JSON mdb_nonEmptyStringForKey:@"title"] ?: [JSON mdb_nonEmptyStringForKey:@"original_title"];
    if (movieID <= 0 || !title) {
        return nil;
    }

    NSMutableArray<NSNumber *> *genreIDs = [NSMutableArray array];
    for (id value in [JSON mdb_arrayForKey:@"genre_ids"] ?: @[]) {
        if ([value isKindOfClass:[NSNumber class]]) {
            [genreIDs addObject:value];
        }
    }
    // Detail responses have full genre objects instead of ids.
    for (NSDictionary *genre in [JSON mdb_dictionaryArrayForKey:@"genres"]) {
        NSNumber *genreID = [genre mdb_numberForKey:@"id"];
        if (genreID != nil) {
            [genreIDs addObject:genreID];
        }
    }

    return [self initWithMovieID:movieID
                           title:title
                        overview:[JSON mdb_nonEmptyStringForKey:@"overview"]
                      posterPath:[JSON mdb_nonEmptyStringForKey:@"poster_path"]
                    backdropPath:[JSON mdb_nonEmptyStringForKey:@"backdrop_path"]
                     releaseDate:[MDBFormatting dateFromTMDBString:[JSON mdb_stringForKey:@"release_date"]]
                     voteAverage:[JSON mdb_doubleForKey:@"vote_average" defaultValue:0]
                       voteCount:[JSON mdb_integerForKey:@"vote_count" defaultValue:0]
                      popularity:[JSON mdb_doubleForKey:@"popularity" defaultValue:0]
                        genreIDs:genreIDs];
}

- (instancetype)initWithMovieID:(NSInteger)movieID
                          title:(NSString *)title
                       overview:(nullable NSString *)overview
                     posterPath:(nullable NSString *)posterPath
                   backdropPath:(nullable NSString *)backdropPath
                    releaseDate:(nullable NSDate *)releaseDate
                    voteAverage:(double)voteAverage
                      voteCount:(NSInteger)voteCount
                     popularity:(double)popularity
                       genreIDs:(nullable NSArray<NSNumber *> *)genreIDs {
    self = [super init];
    if (self) {
        _movieID = movieID;
        _title = [title copy];
        _overview = [overview copy];
        _posterPath = [posterPath copy];
        _backdropPath = [backdropPath copy];
        _releaseDate = [releaseDate copy];
        _voteAverage = voteAverage;
        _voteCount = voteCount;
        _popularity = popularity;
        _genreIDs = [genreIDs copy] ?: @[];
    }
    return self;
}

+ (NSArray<MDBMovie *> *)moviesFromJSONArray:(nullable NSArray *)array {
    NSMutableArray<MDBMovie *> *movies = [NSMutableArray arrayWithCapacity:array.count];
    NSMutableSet<NSNumber *> *seen = [NSMutableSet set];
    for (id element in array) {
        if (![element isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        MDBMovie *movie = [[MDBMovie alloc] initWithJSON:element];
        // TMDB pages sometimes repeat a movie when its rank shifts between requests.
        if (movie && ![seen containsObject:@(movie.movieID)]) {
            [seen addObject:@(movie.movieID)];
            [movies addObject:movie];
        }
    }
    return [movies copy];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[MDBMovie class]]) {
        return NO;
    }
    return self.movieID == ((MDBMovie *)object).movieID;
}

- (NSUInteger)hash {
    return (NSUInteger)self.movieID;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBMovie %ld \"%@\" %.1f>", (long)self.movieID, self.title, self.voteAverage];
}

@end
