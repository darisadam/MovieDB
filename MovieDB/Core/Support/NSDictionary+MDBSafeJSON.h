//
//  NSDictionary+MDBSafeJSON.h
//  MovieDB
//
//  Typed accessors for JSON dictionaries. Every getter checks the class of the value,
//  so a null or a number where we expect a string never reaches the models.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (MDBSafeJSON)

- (nullable NSString *)mdb_stringForKey:(NSString *)key;
/// Same as mdb_stringForKey: but treats an empty string as missing.
- (nullable NSString *)mdb_nonEmptyStringForKey:(NSString *)key;
- (nullable NSNumber *)mdb_numberForKey:(NSString *)key;
- (NSInteger)mdb_integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (long long)mdb_longLongForKey:(NSString *)key defaultValue:(long long)defaultValue;
- (double)mdb_doubleForKey:(NSString *)key defaultValue:(double)defaultValue;
- (BOOL)mdb_boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (nullable NSArray *)mdb_arrayForKey:(NSString *)key;
- (nullable NSDictionary *)mdb_dictionaryForKey:(NSString *)key;
/// Only the elements that are dictionaries. Never nil.
- (NSArray<NSDictionary *> *)mdb_dictionaryArrayForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
