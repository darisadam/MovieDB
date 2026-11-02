//
//  MDBFormatting.m
//  MovieDB
//

#import "MDBFormatting.h"

@implementation MDBFormatting

+ (NSDateFormatter *)tmdbDateParser {
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.dateFormat = @"yyyy-MM-dd";
  });
  return formatter;
}

+ (NSDateFormatter *)mediumDateFormatter {
  static NSDateFormatter *formatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterNoStyle;
  });
  return formatter;
}

+ (NSCalendar *)utcCalendar {
  static NSCalendar *calendar;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  });
  return calendar;
}

+ (nullable NSDate *)dateFromTMDBString:(nullable NSString *)string {
  NSString *value = string;
  if (value.length < 10) {
    return nil;
  }
  return [[self tmdbDateParser] dateFromString:[value substringToIndex:10]];
}

+ (NSString *)yearStringFromDate:(nullable NSDate *)date {
  NSDate *value = date;
  if (!value) {
    return @"";
  }
  NSInteger year = [[self utcCalendar] component:NSCalendarUnitYear fromDate:value];
  return [NSString stringWithFormat:@"%ld", (long)year];
}

+ (NSString *)mediumDateStringFromDate:(nullable NSDate *)date {
  NSDate *value = date;
  return value ? [[self mediumDateFormatter] stringFromDate:value] : @"";
}

+ (NSString *)runtimeStringFromMinutes:(NSInteger)minutes {
  if (minutes <= 0) {
    return @"";
  }
  NSInteger hours = minutes / 60;
  NSInteger rest = minutes % 60;
  if (hours == 0) {
    return [NSString stringWithFormat:@"%ldm", (long)rest];
  }
  if (rest == 0) {
    return [NSString stringWithFormat:@"%ldh", (long)hours];
  }
  return [NSString stringWithFormat:@"%ldh %ldm", (long)hours, (long)rest];
}

+ (NSString *)ratingStringFromVoteAverage:(double)voteAverage {
  return [NSString stringWithFormat:@"%.1f", MAX(0.0, MIN(10.0, voteAverage))];
}

+ (NSString *)compactCountStringFromCount:(NSInteger)count {
  if (count < 1000) {
    return [NSString stringWithFormat:@"%ld", (long)MAX(0, count)];
  }
  double thousands = count / 1000.0;
  if (thousands < 10) {
    return [NSString stringWithFormat:@"%.1fk", floor(thousands * 10) / 10];
  }
  return [NSString stringWithFormat:@"%ldk", (long)floor(thousands)];
}

+ (NSString *)compactCurrencyStringFromAmount:(long long)amount {
  if (amount <= 0) {
    return @"";
  }
  if (amount >= 1000000000LL) {
    return [NSString stringWithFormat:@"$%.1fB", amount / 1000000000.0];
  }
  if (amount >= 1000000LL) {
    return [NSString stringWithFormat:@"$%.0fM", amount / 1000000.0];
  }
  if (amount >= 1000LL) {
    return [NSString stringWithFormat:@"$%.0fK", amount / 1000.0];
  }
  return [NSString stringWithFormat:@"$%lld", amount];
}

+ (NSInteger)yearsFromDate:(NSDate *)start toDate:(NSDate *)end {
  NSDateComponents *components = [[self utcCalendar] components:NSCalendarUnitYear fromDate:start toDate:end options:0];
  return MAX(0, components.year);
}

@end
