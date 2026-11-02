//
//  MDBPreferences.m
//  MovieDB
//

#import "MDBPreferences.h"
#import "MDBLog.h"

NSNotificationName const MDBPreferencesDidChangeNotification = @"MDBPreferencesDidChangeNotification";

static NSString *const MDBLanguageDefaultsKey = @"preferences.language";
static NSString *const MDBRegionDefaultsKey = @"preferences.region";

@implementation MDBPreferenceOption

- (instancetype)initWithCode:(NSString *)code title:(NSString *)title {
    self = [super init];
    if (self) {
        _code = [code copy];
        _title = [title copy];
    }
    return self;
}

@end

@interface MDBPreferences ()
@property (nonatomic, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@end

@implementation MDBPreferences

+ (NSArray<MDBPreferenceOption *> *)languageOptions {
    static NSArray<MDBPreferenceOption *> *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            [[MDBPreferenceOption alloc] initWithCode:@"en-US" title:@"English"],
            [[MDBPreferenceOption alloc] initWithCode:@"id-ID" title:@"Bahasa Indonesia"],
            [[MDBPreferenceOption alloc] initWithCode:@"es-ES" title:@"Español"],
            [[MDBPreferenceOption alloc] initWithCode:@"fr-FR" title:@"Français"],
            [[MDBPreferenceOption alloc] initWithCode:@"de-DE" title:@"Deutsch"],
            [[MDBPreferenceOption alloc] initWithCode:@"pt-BR" title:@"Português (Brasil)"],
            [[MDBPreferenceOption alloc] initWithCode:@"ja-JP" title:@"日本語"],
            [[MDBPreferenceOption alloc] initWithCode:@"ko-KR" title:@"한국어"],
        ];
    });
    return options;
}

+ (NSArray<MDBPreferenceOption *> *)regionOptions {
    static NSArray<MDBPreferenceOption *> *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *english = [NSLocale localeWithLocaleIdentifier:@"en"];
        NSArray<NSString *> *codes = @[@"US", @"ID", @"GB", @"AU", @"CA", @"IN", @"SG", @"MY", @"JP", @"KR", @"DE", @"FR", @"ES", @"BR"];
        NSMutableArray<MDBPreferenceOption *> *built = [NSMutableArray arrayWithCapacity:codes.count];
        for (NSString *code in codes) {
            NSString *title = [english displayNameForKey:NSLocaleCountryCode value:code] ?: code;
            [built addObject:[[MDBPreferenceOption alloc] initWithCode:code title:title]];
        }
        options = [built copy];
    });
    return options;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
        _notificationCenter = notificationCenter;
    }
    return self;
}

+ (nullable MDBPreferenceOption *)optionWithCode:(NSString *)code inOptions:(NSArray<MDBPreferenceOption *> *)options {
    for (MDBPreferenceOption *option in options) {
        if ([option.code isEqualToString:code]) {
            return option;
        }
    }
    return nil;
}

- (NSString *)languageCode {
    NSString *stored = [self.userDefaults stringForKey:MDBLanguageDefaultsKey];
    if (stored && [self.class optionWithCode:stored inOptions:self.class.languageOptions]) {
        return stored;
    }
    return @"en-US";
}

- (void)setLanguageCode:(NSString *)languageCode {
    if ([languageCode isEqualToString:self.languageCode]) {
        return;
    }
    [self.userDefaults setObject:languageCode forKey:MDBLanguageDefaultsKey];
    MDBLogInfo(MDBLogCategoryApp, @"Language set to %@", languageCode);
    [self.notificationCenter postNotificationName:MDBPreferencesDidChangeNotification object:self];
}

- (NSString *)regionCode {
    NSString *stored = [self.userDefaults stringForKey:MDBRegionDefaultsKey];
    if (stored && [self.class optionWithCode:stored inOptions:self.class.regionOptions]) {
        return stored;
    }
    id deviceRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if ([deviceRegion isKindOfClass:[NSString class]] && [self.class optionWithCode:deviceRegion inOptions:self.class.regionOptions]) {
        return deviceRegion;
    }
    return @"US";
}

- (void)setRegionCode:(NSString *)regionCode {
    if ([regionCode isEqualToString:self.regionCode]) {
        return;
    }
    [self.userDefaults setObject:regionCode forKey:MDBRegionDefaultsKey];
    MDBLogInfo(MDBLogCategoryApp, @"Region set to %@", regionCode);
    [self.notificationCenter postNotificationName:MDBPreferencesDidChangeNotification object:self];
}

- (NSString *)languageTitle {
    return [self.class optionWithCode:self.languageCode inOptions:self.class.languageOptions].title ?: self.languageCode;
}

- (NSString *)regionTitle {
    return [self.class optionWithCode:self.regionCode inOptions:self.class.regionOptions].title ?: self.regionCode;
}

@end
