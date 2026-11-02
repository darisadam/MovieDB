//
//  MDBPreferences.m
//  MovieDB
//

#import "MDBPreferences.h"
#import "MDBLog.h"
#import "MDBObservable.h"

static NSString *const MDBLanguageDefaultsKey = @"preferences.language";
static NSString *const MDBRegionDefaultsKey = @"preferences.region";
static NSString *const MDBFallbackLanguage = @"en-US";
static NSString *const MDBFallbackRegion = @"US";

@implementation MDBPreferenceOption

- (instancetype)initWithCode:(NSString *)code title:(NSString *)title {
  self = [super init];
  if (self) {
    _code = [code copy];
    _title = [title copy];
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  return [object isKindOfClass:[MDBPreferenceOption class]] && [((MDBPreferenceOption *)object).code isEqualToString:self.code];
}

- (NSUInteger)hash {
  return self.code.hash;
}

@end

@implementation MDBPreferenceSnapshot

- (instancetype)initWithLanguage:(MDBPreferenceOption *)language region:(MDBPreferenceOption *)region {
  self = [super init];
  if (self) {
    _language = language;
    _region = region;
  }
  return self;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MDBPreferenceSnapshot class]]) {
    return NO;
  }
  MDBPreferenceSnapshot *other = object;
  return [other.language isEqual:self.language] && [other.region isEqual:self.region];
}

- (NSUInteger)hash {
  return self.language.hash ^ self.region.hash;
}

@end

@interface MDBPreferences ()
@property (nonatomic, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, readonly) MDBSubject<MDBPreferenceSnapshot *> *subject;
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
    NSArray<NSString *> *codes =
        @[ @"US", @"ID", @"GB", @"AU", @"CA", @"IN", @"SG", @"MY", @"JP", @"KR", @"DE", @"FR", @"ES", @"BR" ];
    NSMutableArray<MDBPreferenceOption *> *built = [NSMutableArray arrayWithCapacity:codes.count];
    for (NSString *code in codes) {
      NSString *title = [english displayNameForKey:NSLocaleCountryCode value:code] ?: code;
      [built addObject:[[MDBPreferenceOption alloc] initWithCode:code title:title]];
    }
    options = [built copy];
  });
  return options;
}

+ (nullable MDBPreferenceOption *)optionWithCode:(nullable NSString *)code inOptions:(NSArray<MDBPreferenceOption *> *)options {
  for (MDBPreferenceOption *option in options) {
    if ([option.code isEqual:code]) {
      return option;
    }
  }
  return nil;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
  self = [super init];
  if (self) {
    _userDefaults = userDefaults;
    _subject = [[MDBSubject alloc] init];
    [_subject send:[self makeSnapshot]];
  }
  return self;
}

- (MDBObservable<MDBPreferenceSnapshot *> *)current {
  return self.subject;
}

#pragma mark - Values

- (MDBPreferenceOption *)languageOption {
  MDBPreferenceOption *stored = [self.class optionWithCode:[self.userDefaults stringForKey:MDBLanguageDefaultsKey]
                                                 inOptions:self.class.languageOptions];
  return stored
             ?: (MDBPreferenceOption *_Nonnull)[self.class optionWithCode:MDBFallbackLanguage
                                                                inOptions:self.class.languageOptions];
}

- (MDBPreferenceOption *)regionOption {
  NSArray<MDBPreferenceOption *> *options = self.class.regionOptions;
  MDBPreferenceOption *stored = [self.class optionWithCode:[self.userDefaults stringForKey:MDBRegionDefaultsKey]
                                                 inOptions:options];
  if (stored) {
    return stored;
  }
  id deviceRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
  NSString *deviceCode = [deviceRegion isKindOfClass:[NSString class]] ? deviceRegion : nil;
  MDBPreferenceOption *device = [self.class optionWithCode:deviceCode inOptions:options];
  return device ?: (MDBPreferenceOption *_Nonnull)[self.class optionWithCode:MDBFallbackRegion inOptions:options];
}

- (MDBPreferenceSnapshot *)makeSnapshot {
  return [[MDBPreferenceSnapshot alloc] initWithLanguage:[self languageOption] region:[self regionOption]];
}

- (NSString *)languageCode {
  return [self languageOption].code;
}

- (NSString *)regionCode {
  return [self regionOption].code;
}

- (void)setLanguageCode:(NSString *)languageCode {
  [self storeCode:languageCode forKey:MDBLanguageDefaultsKey options:self.class.languageOptions];
}

- (void)setRegionCode:(NSString *)regionCode {
  [self storeCode:regionCode forKey:MDBRegionDefaultsKey options:self.class.regionOptions];
}

- (void)storeCode:(NSString *)code forKey:(NSString *)key options:(NSArray<MDBPreferenceOption *> *)options {
  if (![self.class optionWithCode:code inOptions:options]) {
    MDBLogError(MDBLogCategoryApp, @"Ignoring unknown preference %@ for %@", code, key);
    return;
  }
  MDBPreferenceSnapshot *before = [self makeSnapshot];
  [self.userDefaults setObject:code forKey:key];
  MDBPreferenceSnapshot *after = [self makeSnapshot];
  if (![after isEqual:before]) {
    MDBLogInfo(MDBLogCategoryApp, @"Preferences now %@ / %@", after.language.code, after.region.code);
    [self.subject send:after];
  }
}

@end
