//
//  MDBTMDBMovieService.m
//  MovieDB
//

#import "MDBTMDBMovieService.h"
#import "MDBAPIClient.h"
#import "MDBEndpoint.h"
#import "MDBGenre.h"
#import "MDBMovie.h"
#import "MDBMovieDetail.h"
#import "MDBPage.h"
#import "MDBPerson.h"
#import "MDBPreferences.h"
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

@interface MDBTMDBMovieService ()
@property (nonatomic, readonly) MDBAPIClient *client;
@property (nonatomic, readonly) MDBPreferences *preferences;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, NSString *> *genreNames;
@property (nonatomic, readonly) NSObject *genreLock;
@end

@implementation MDBTMDBMovieService

- (instancetype)initWithClient:(MDBAPIClient *)client preferences:(MDBPreferences *)preferences {
    self = [super init];
    if (self) {
        _client = client;
        _preferences = preferences;
        _genreNames = [NSMutableDictionary dictionary];
        _genreLock = [[NSObject alloc] init];
    }
    return self;
}

#pragma mark - Parsers

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

#pragma mark - Helpers

- (NSMutableDictionary<NSString *, NSString *> *)baseQueryWithPage:(NSInteger)page {
    NSMutableDictionary<NSString *, NSString *> *query = [NSMutableDictionary dictionary];
    query[@"language"] = self.preferences.languageCode;
    if (page > 0) {
        query[@"page"] = [NSString stringWithFormat:@"%ld", (long)page];
    }
    return query;
}

#pragma mark - MDBMovieService

- (id<MDBCancellable>)fetchMovieList:(MDBMovieListKind)kind page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
    NSString *path = @"movie/popular";
    NSMutableDictionary<NSString *, NSString *> *query = [self baseQueryWithPage:page];
    switch (kind) {
        case MDBMovieListKindNowPlaying:
            path = @"movie/now_playing";
            query[@"region"] = self.preferences.regionCode;
            break;
        case MDBMovieListKindPopular:
            path = @"movie/popular";
            break;
        case MDBMovieListKindTopRated:
            path = @"movie/top_rated";
            break;
        case MDBMovieListKindUpcoming:
            path = @"movie/upcoming";
            query[@"region"] = self.preferences.regionCode;
            break;
        case MDBMovieListKindTrending:
            path = @"trending/movie/week";
            break;
    }
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:path query:query];
    return [self.client GET:endpoint parser:[self.class moviePageParser] completion:completion];
}

- (id<MDBCancellable>)searchMoviesWithQuery:(NSString *)queryText page:(NSInteger)page completion:(MDBMoviePageCompletion)completion {
    NSMutableDictionary<NSString *, NSString *> *query = [self baseQueryWithPage:page];
    query[@"query"] = queryText;
    query[@"include_adult"] = @"false";
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:@"search/movie" query:query];
    return [self.client GET:endpoint parser:[self.class moviePageParser] completion:completion];
}

- (id<MDBCancellable>)discoverMoviesWithGenreID:(NSInteger)genreID
                                           sort:(MDBDiscoverSort)sort
                                           page:(NSInteger)page
                                     completion:(MDBMoviePageCompletion)completion {
    NSMutableDictionary<NSString *, NSString *> *query = [self baseQueryWithPage:page];
    query[@"with_genres"] = [NSString stringWithFormat:@"%ld", (long)genreID];
    query[@"include_adult"] = @"false";
    switch (sort) {
        case MDBDiscoverSortPopularity:
            query[@"sort_by"] = @"popularity.desc";
            break;
        case MDBDiscoverSortRating:
            query[@"sort_by"] = @"vote_average.desc";
            // Without a floor the top is full of films with three votes and a perfect 10.
            query[@"vote_count.gte"] = @"300";
            break;
        case MDBDiscoverSortNewest: {
            query[@"sort_by"] = @"primary_release_date.desc";
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd";
            query[@"primary_release_date.lte"] = [formatter stringFromDate:[NSDate date]];
            query[@"vote_count.gte"] = @"10";
            break;
        }
    }
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:@"discover/movie" query:query];
    return [self.client GET:endpoint parser:[self.class moviePageParser] completion:completion];
}

- (id<MDBCancellable>)fetchGenresWithCompletion:(MDBGenreListCompletion)completion {
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:@"genre/movie/list" query:[self baseQueryWithPage:0]];
    __weak typeof(self) weakSelf = self;
    MDBGenreListCompletion callback = [completion copy];
    return [self.client GET:endpoint parser:^id _Nullable(id JSON) {
        if (![JSON isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        return [MDBGenre genresFromJSONArray:[(NSDictionary *)JSON mdb_arrayForKey:@"genres"]];
    } completion:^(id _Nullable result, NSError *_Nullable error) {
        NSArray<MDBGenre *> *genres = result;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && genres.count > 0) {
            @synchronized (strongSelf.genreLock) {
                for (MDBGenre *genre in genres) {
                    strongSelf.genreNames[@(genre.genreID)] = genre.name;
                }
            }
        }
        callback(genres, error);
    }];
}

- (id<MDBCancellable>)fetchMovieDetailWithID:(NSInteger)movieID completion:(MDBMovieDetailCompletion)completion {
    NSMutableDictionary<NSString *, NSString *> *query = [self baseQueryWithPage:0];
    query[@"append_to_response"] = @"credits,videos,recommendations";
    // Trailers are often only uploaded in English, so ask for those too.
    NSString *language = [[self.preferences.languageCode componentsSeparatedByString:@"-"] firstObject] ?: @"en";
    query[@"include_video_language"] = [NSString stringWithFormat:@"%@,en,null", language];
    NSString *path = [NSString stringWithFormat:@"movie/%ld", (long)movieID];
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:path query:query];
    return [self.client GET:endpoint parser:^id _Nullable(id JSON) {
        return [JSON isKindOfClass:[NSDictionary class]] ? [[MDBMovieDetail alloc] initWithJSON:JSON] : nil;
    } completion:completion];
}

- (id<MDBCancellable>)fetchPersonWithID:(NSInteger)personID completion:(MDBPersonCompletion)completion {
    NSMutableDictionary<NSString *, NSString *> *query = [self baseQueryWithPage:0];
    query[@"append_to_response"] = @"movie_credits";
    NSString *path = [NSString stringWithFormat:@"person/%ld", (long)personID];
    MDBEndpoint *endpoint = [MDBEndpoint endpointWithPath:path query:query];
    return [self.client GET:endpoint parser:^id _Nullable(id JSON) {
        return [JSON isKindOfClass:[NSDictionary class]] ? [[MDBPerson alloc] initWithJSON:JSON] : nil;
    } completion:completion];
}

- (NSArray<NSString *> *)genreNamesForIDs:(NSArray<NSNumber *> *)genreIDs {
    NSMutableArray<NSString *> *names = [NSMutableArray arrayWithCapacity:genreIDs.count];
    @synchronized (self.genreLock) {
        for (NSNumber *genreID in genreIDs) {
            NSString *name = self.genreNames[genreID];
            if (name) {
                [names addObject:name];
            }
        }
    }
    return [names copy];
}

@end
