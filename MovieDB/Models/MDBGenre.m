//
//  MDBGenre.m
//  MovieDB
//

#import "MDBGenre.h"
#import "NSDictionary+MDBSafeJSON.h"

@implementation MDBGenre

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSInteger genreID = [JSON mdb_integerForKey:@"id" defaultValue:0];
    NSString *name = [JSON mdb_nonEmptyStringForKey:@"name"];
    if (genreID <= 0 || !name) {
        return nil;
    }
    return [self initWithGenreID:genreID name:name];
}

- (instancetype)initWithGenreID:(NSInteger)genreID name:(NSString *)name {
    self = [super init];
    if (self) {
        _genreID = genreID;
        _name = [name copy];
    }
    return self;
}

+ (NSArray<MDBGenre *> *)genresFromJSONArray:(nullable NSArray *)array {
    NSMutableArray<MDBGenre *> *genres = [NSMutableArray arrayWithCapacity:array.count];
    for (id element in array) {
        MDBGenre *genre = [element isKindOfClass:[NSDictionary class]] ? [[MDBGenre alloc] initWithJSON:element] : nil;
        if (genre) {
            [genres addObject:genre];
        }
    }
    return [genres copy];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[MDBGenre class]] && ((MDBGenre *)object).genreID == self.genreID;
}

- (NSUInteger)hash {
    return (NSUInteger)self.genreID;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBGenre %ld %@>", (long)self.genreID, self.name];
}

@end
