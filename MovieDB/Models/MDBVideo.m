//
//  MDBVideo.m
//  MovieDB
//

#import "MDBVideo.h"
#import "NSDictionary+MDBSafeJSON.h"

@implementation MDBVideo

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSString *key = [JSON mdb_nonEmptyStringForKey:@"key"];
    NSString *site = [JSON mdb_nonEmptyStringForKey:@"site"];
    if (!key || !site) {
        return nil;
    }
    self = [super init];
    if (self) {
        _key = [key copy];
        _site = [site copy];
        _name = [[JSON mdb_nonEmptyStringForKey:@"name"] copy] ?: @"Video";
        _type = [[JSON mdb_nonEmptyStringForKey:@"type"] copy] ?: @"Video";
        _official = [JSON mdb_boolForKey:@"official" defaultValue:NO];

        NSString *published = [JSON mdb_stringForKey:@"published_at"];
        if (published.length > 0) {
            NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
            _publishedAt = [formatter dateFromString:published];
        }
    }
    return self;
}

- (BOOL)isYouTube {
    return [self.site caseInsensitiveCompare:@"YouTube"] == NSOrderedSame;
}

- (nullable NSURL *)watchURL {
    if (!self.isYouTube) {
        return nil;
    }
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://www.youtube.com/watch"];
    components.queryItems = @[[NSURLQueryItem queryItemWithName:@"v" value:self.key]];
    return components.URL;
}

- (nullable NSURL *)thumbnailURL {
    if (!self.isYouTube) {
        return nil;
    }
    NSString *escaped = [self.key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://img.youtube.com/vi/%@/hqdefault.jpg", escaped]];
}

+ (NSInteger)rankForType:(NSString *)type {
    NSArray<NSString *> *order = @[@"Trailer", @"Teaser", @"Clip", @"Featurette", @"Behind the Scenes"];
    NSUInteger index = [order indexOfObject:type];
    return index == NSNotFound ? (NSInteger)order.count : (NSInteger)index;
}

+ (NSArray<MDBVideo *> *)playableVideosFromJSONArray:(nullable NSArray *)array {
    NSMutableArray<MDBVideo *> *videos = [NSMutableArray array];
    for (id element in array) {
        MDBVideo *video = [element isKindOfClass:[NSDictionary class]] ? [[MDBVideo alloc] initWithJSON:element] : nil;
        if (video.isYouTube) {
            [videos addObject:video];
        }
    }
    [videos sortUsingComparator:^NSComparisonResult(MDBVideo *lhs, MDBVideo *rhs) {
        NSInteger leftRank = [MDBVideo rankForType:lhs.type];
        NSInteger rightRank = [MDBVideo rankForType:rhs.type];
        if (leftRank != rightRank) {
            return leftRank < rightRank ? NSOrderedAscending : NSOrderedDescending;
        }
        if (lhs.isOfficial != rhs.isOfficial) {
            return lhs.isOfficial ? NSOrderedAscending : NSOrderedDescending;
        }
        NSDate *leftDate = lhs.publishedAt ?: [NSDate distantPast];
        NSDate *rightDate = rhs.publishedAt ?: [NSDate distantPast];
        return [rightDate compare:leftDate];
    }];
    return [videos copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBVideo %@ %@ \"%@\">", self.type, self.key, self.name];
}

@end
