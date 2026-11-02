//
//  MDBPreferences.h
//  MovieDB
//
//  Region and language choices from the Menu tab. They are sent to TMDB as the
//  region and language query items.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const MDBPreferencesDidChangeNotification;

@interface MDBPreferenceOption : NSObject

@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithCode:(NSString *)code title:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBPreferences : NSObject

@property (class, nonatomic, readonly) NSArray<MDBPreferenceOption *> *languageOptions;
@property (class, nonatomic, readonly) NSArray<MDBPreferenceOption *> *regionOptions;

/// "en-US" style code.
@property (nonatomic, copy) NSString *languageCode;
/// Two letter country code, "ID" for example.
@property (nonatomic, copy) NSString *regionCode;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
                  notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)languageTitle;
- (NSString *)regionTitle;

@end

NS_ASSUME_NONNULL_END
