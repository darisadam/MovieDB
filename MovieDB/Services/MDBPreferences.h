//
//  MDBPreferences.h
//  MovieDB
//
//  Region and language from the Menu tab. They go to TMDB as the region and language query items.
//

#import <Foundation/Foundation.h>

@class MDBObservable<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBPreferenceOption : NSObject

@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithCode:(NSString *)code title:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

/// The current choice, published whenever it changes.
@interface MDBPreferenceSnapshot : NSObject

@property (nonatomic, readonly) MDBPreferenceOption *language;
@property (nonatomic, readonly) MDBPreferenceOption *region;

- (instancetype)initWithLanguage:(MDBPreferenceOption *)language region:(MDBPreferenceOption *)region NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBPreferences : NSObject

@property (class, nonatomic, readonly) NSArray<MDBPreferenceOption *> *languageOptions;
@property (class, nonatomic, readonly) NSArray<MDBPreferenceOption *> *regionOptions;

/// "en-US" style code. Unknown codes are ignored.
@property (nonatomic, copy) NSString *languageCode;
/// Two letter country code, "ID" for example. Unknown codes are ignored.
@property (nonatomic, copy) NSString *regionCode;

/// Replays the current snapshot and emits again after every change.
@property (nonatomic, readonly) MDBObservable<MDBPreferenceSnapshot *> *current;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
