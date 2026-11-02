//
//  MDBPerson.h
//  MovieDB
//
//  Built from /person/{id}?append_to_response=movie_credits
//

#import <Foundation/Foundation.h>

@class MDBMovie;

NS_ASSUME_NONNULL_BEGIN

@interface MDBPersonCredit : NSObject

@property (nonatomic, readonly) MDBMovie *movie;
@property (nonatomic, copy, readonly, nullable) NSString *character;

- (instancetype)initWithMovie:(MDBMovie *)movie character:(nullable NSString *)character NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBPerson : NSObject

@property (nonatomic, readonly) NSInteger personID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly, nullable) NSString *biography;
@property (nonatomic, copy, readonly, nullable) NSDate *birthday;
@property (nonatomic, copy, readonly, nullable) NSDate *deathday;
@property (nonatomic, copy, readonly, nullable) NSString *placeOfBirth;
@property (nonatomic, copy, readonly, nullable) NSString *knownForDepartment;
@property (nonatomic, copy, readonly, nullable) NSString *profilePath;

/// Every acting credit, newest first. Credits without a date go last.
@property (nonatomic, copy, readonly) NSArray<MDBPersonCredit *> *filmography;
/// The most voted credits, used for the Known For row.
@property (nonatomic, copy, readonly) NSArray<MDBPersonCredit *> *knownFor;

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
