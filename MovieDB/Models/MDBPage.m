//
//  MDBPage.m
//  MovieDB
//

#import "MDBPage.h"
#import "NSDictionary+MDBSafeJSON.h"

// TMDB refuses pages past 500 even when total_pages says otherwise.
static const NSInteger MDBMaximumTMDBPage = 500;

@implementation MDBPage

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON itemParser:(NSArray * (^)(NSArray *items))itemParser {
    if (![JSON isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = [JSON mdb_arrayForKey:@"results"];
    if (!items) {
        return nil;
    }
    NSInteger page = [JSON mdb_integerForKey:@"page" defaultValue:1];
    NSInteger totalPages = [JSON mdb_integerForKey:@"total_pages" defaultValue:page];
    NSInteger totalResults = [JSON mdb_integerForKey:@"total_results" defaultValue:(NSInteger)items.count];
    return [self initWithPage:page totalPages:totalPages totalResults:totalResults results:itemParser(items) ?: @[]];
}

- (instancetype)initWithPage:(NSInteger)page
                  totalPages:(NSInteger)totalPages
                totalResults:(NSInteger)totalResults
                     results:(NSArray *)results {
    self = [super init];
    if (self) {
        _page = MAX(1, page);
        _totalPages = MIN(MAX(_page, totalPages), MDBMaximumTMDBPage);
        _totalResults = MAX(0, totalResults);
        _results = [results copy];
    }
    return self;
}

- (BOOL)hasMore {
    return self.page < self.totalPages;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MDBPage %ld/%ld, %lu items, %ld total>",
            (long)self.page, (long)self.totalPages, (unsigned long)self.results.count, (long)self.totalResults];
}

@end
