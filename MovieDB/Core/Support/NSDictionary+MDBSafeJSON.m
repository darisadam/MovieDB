//
//  NSDictionary+MDBSafeJSON.m
//  MovieDB
//

#import "NSDictionary+MDBSafeJSON.h"

@implementation NSDictionary (MDBSafeJSON)

- (nullable NSString *)mdb_stringForKey:(NSString *)key {
  id value = self[key];
  return [value isKindOfClass:[NSString class]] ? value : nil;
}

- (nullable NSString *)mdb_nonEmptyStringForKey:(NSString *)key {
  NSString *value = [self mdb_stringForKey:key];
  NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  return trimmed.length > 0 ? value : nil;
}

- (nullable NSNumber *)mdb_numberForKey:(NSString *)key {
  id value = self[key];
  return [value isKindOfClass:[NSNumber class]] ? value : nil;
}

- (NSInteger)mdb_integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
  NSNumber *number = [self mdb_numberForKey:key];
  return number != nil ? number.integerValue : defaultValue;
}

- (long long)mdb_longLongForKey:(NSString *)key defaultValue:(long long)defaultValue {
  NSNumber *number = [self mdb_numberForKey:key];
  return number != nil ? number.longLongValue : defaultValue;
}

- (double)mdb_doubleForKey:(NSString *)key defaultValue:(double)defaultValue {
  NSNumber *number = [self mdb_numberForKey:key];
  return number != nil ? number.doubleValue : defaultValue;
}

- (BOOL)mdb_boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
  NSNumber *number = [self mdb_numberForKey:key];
  return number != nil ? number.boolValue : defaultValue;
}

- (nullable NSArray *)mdb_arrayForKey:(NSString *)key {
  id value = self[key];
  return [value isKindOfClass:[NSArray class]] ? value : nil;
}

- (nullable NSDictionary *)mdb_dictionaryForKey:(NSString *)key {
  id value = self[key];
  return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

- (NSArray<NSDictionary *> *)mdb_dictionaryArrayForKey:(NSString *)key {
  NSArray *array = [self mdb_arrayForKey:key];
  if (array.count == 0) {
    return @[];
  }
  NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:array.count];
  for (id element in array) {
    if ([element isKindOfClass:[NSDictionary class]]) {
      [result addObject:element];
    }
  }
  return [result copy];
}

@end
