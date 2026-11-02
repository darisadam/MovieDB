//
//  MDBFormatting.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBFormatting : NSObject

/// Parses TMDB dates like "2016-06-10". Returns nil for empty or malformed strings.
+ (nullable NSDate *)dateFromTMDBString:(nullable NSString *)string;
/// "2016", or an empty string when the date is unknown.
+ (NSString *)yearStringFromDate:(nullable NSDate *)date;
/// "Jun 10, 2016" in the user's locale.
+ (NSString *)mediumDateStringFromDate:(nullable NSDate *)date;
/// "2h 9m". Empty when minutes is zero or less.
+ (NSString *)runtimeStringFromMinutes:(NSInteger)minutes;
/// One decimal, "6.8".
+ (NSString *)ratingStringFromVoteAverage:(double)voteAverage;
/// "1.2k", "12k", "980".
+ (NSString *)compactCountStringFromCount:(NSInteger)count;
/// "$90M", "$1.2B". Empty for zero.
+ (NSString *)compactCurrencyStringFromAmount:(long long)amount;
/// Whole years between two dates, used for an actor's age.
+ (NSInteger)yearsFromDate:(NSDate *)start toDate:(NSDate *)end;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
