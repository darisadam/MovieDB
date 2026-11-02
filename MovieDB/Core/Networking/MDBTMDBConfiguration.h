//
//  MDBTMDBConfiguration.h
//  MovieDB
//
//  Where the TMDB token comes from: Configs/Secrets.xcconfig, then Info.plist (TMDBAccessToken), then here.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBTMDBConfiguration : NSObject

@property (nonatomic, copy, readonly) NSString *accessToken;
@property (nonatomic, copy, readonly) NSURL *apiBaseURL;
@property (nonatomic, copy, readonly) NSURL *imageBaseURL;
@property (nonatomic, readonly) BOOL hasAccessToken;

+ (instancetype)configurationWithBundle:(NSBundle *)bundle;

- (instancetype)initWithAccessToken:(nullable NSString *)accessToken
                         apiBaseURL:(NSURL *)apiBaseURL
                       imageBaseURL:(NSURL *)imageBaseURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Never prints the token itself, only whether one is set and its length.
- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
