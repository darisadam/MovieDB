//
//  MDBPerson.m
//  MovieDB
//

#import "MDBPerson.h"
#import "MDBFormatting.h"
#import "MDBMovie.h"
#import "NSDictionary+MDBSafeJSON.h"

static const NSUInteger MDBKnownForLimit = 10;

@implementation MDBPersonCredit

- (instancetype)initWithMovie:(MDBMovie *)movie character:(nullable NSString *)character {
    self = [super init];
    if (self) {
        _movie = movie;
        _character = [character copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBPersonCredit %@ as %@>", self.movie.title, self.character ?: @"?"];
}

@end

@implementation MDBPerson

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSInteger personID = [JSON mdb_integerForKey:@"id" defaultValue:0];
    NSString *name = [JSON mdb_nonEmptyStringForKey:@"name"];
    if (personID <= 0 || !name) {
        return nil;
    }
    self = [super init];
    if (self) {
        _personID = personID;
        _name = [name copy];
        _biography = [[JSON mdb_nonEmptyStringForKey:@"biography"] copy];
        _birthday = [MDBFormatting dateFromTMDBString:[JSON mdb_stringForKey:@"birthday"]];
        _deathday = [MDBFormatting dateFromTMDBString:[JSON mdb_stringForKey:@"deathday"]];
        _placeOfBirth = [[JSON mdb_nonEmptyStringForKey:@"place_of_birth"] copy];
        _knownForDepartment = [[JSON mdb_nonEmptyStringForKey:@"known_for_department"] copy];
        _profilePath = [[JSON mdb_nonEmptyStringForKey:@"profile_path"] copy];

        NSDictionary *credits = [JSON mdb_dictionaryForKey:@"movie_credits"];
        NSMutableArray<MDBPersonCredit *> *all = [NSMutableArray array];
        NSMutableSet<NSNumber *> *seen = [NSMutableSet set];
        for (NSDictionary *item in [credits mdb_dictionaryArrayForKey:@"cast"]) {
            MDBMovie *movie = [[MDBMovie alloc] initWithJSON:item];
            if (!movie || [seen containsObject:@(movie.movieID)]) {
                continue;
            }
            [seen addObject:@(movie.movieID)];
            [all addObject:[[MDBPersonCredit alloc] initWithMovie:movie character:[item mdb_nonEmptyStringForKey:@"character"]]];
        }

        _filmography = [[all sortedArrayUsingComparator:^NSComparisonResult(MDBPersonCredit *lhs, MDBPersonCredit *rhs) {
            NSDate *left = lhs.movie.releaseDate;
            NSDate *right = rhs.movie.releaseDate;
            if (left && right) {
                return [right compare:left];
            }
            if (left || right) {
                return left ? NSOrderedAscending : NSOrderedDescending;
            }
            return [lhs.movie.title compare:rhs.movie.title];
        }] copy];

        NSArray<MDBPersonCredit *> *byVotes = [all sortedArrayUsingComparator:^NSComparisonResult(MDBPersonCredit *lhs, MDBPersonCredit *rhs) {
            if (lhs.movie.voteCount == rhs.movie.voteCount) {
                return NSOrderedSame;
            }
            return lhs.movie.voteCount > rhs.movie.voteCount ? NSOrderedAscending : NSOrderedDescending;
        }];
        _knownFor = [[byVotes subarrayWithRange:NSMakeRange(0, MIN(byVotes.count, MDBKnownForLimit))] copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBPerson %ld %@, %lu credits>",
            (long)self.personID, self.name, (unsigned long)self.filmography.count];
}

@end
