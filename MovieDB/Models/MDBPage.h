//
//  MDBPage.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBPage<__covariant ObjectType> : NSObject

@property (nonatomic, readonly) NSInteger page;
@property (nonatomic, readonly) NSInteger totalPages;
@property (nonatomic, readonly) NSInteger totalResults;
@property (nonatomic, copy, readonly) NSArray<ObjectType> *results;
@property (nonatomic, readonly) BOOL hasMore;

/// Nil when the JSON isn't a paged response.
- (nullable instancetype)initWithJSON:(NSDictionary *)JSON
                           itemParser:(NSArray * (^)(NSArray *items))itemParser;

- (instancetype)initWithPage:(NSInteger)page
                  totalPages:(NSInteger)totalPages
                totalResults:(NSInteger)totalResults
                     results:(NSArray<ObjectType> *)results NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
