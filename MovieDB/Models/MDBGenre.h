//
//  MDBGenre.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBGenre : NSObject <NSCopying>

@property (nonatomic, readonly) NSInteger genreID;
@property (nonatomic, copy, readonly) NSString *name;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;
- (instancetype)initWithGenreID:(NSInteger)genreID name:(NSString *)name NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

+ (NSArray<MDBGenre *> *)genresFromJSONArray:(nullable NSArray *)array;

@end

NS_ASSUME_NONNULL_END
