//
//  MDBCastMember.m
//  MovieDB
//

#import "MDBCastMember.h"
#import "NSDictionary+MDBSafeJSON.h"

@implementation MDBCastMember

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
        _character = [[JSON mdb_nonEmptyStringForKey:@"character"] copy];
        _profilePath = [[JSON mdb_nonEmptyStringForKey:@"profile_path"] copy];
        _order = [JSON mdb_integerForKey:@"order" defaultValue:NSIntegerMax];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBCastMember %ld %@ as %@>", (long)self.personID, self.name, self.character ?: @"?"];
}

@end
