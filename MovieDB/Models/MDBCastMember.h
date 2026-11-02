//
//  MDBCastMember.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBCastMember : NSObject

@property (nonatomic, readonly) NSInteger personID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly, nullable) NSString *character;
@property (nonatomic, copy, readonly, nullable) NSString *profilePath;
@property (nonatomic, readonly) NSInteger order;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
