//
//  MDBTheme.h
//  MovieDB
//
//  Colors and fonts from the Figma "TMDB v2" page. The app is dark only.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (MDBTheme)

+ (UIColor *)mdb_colorWithHex:(uint32_t)hex alpha:(CGFloat)alpha;

@property (class, nonatomic, readonly) UIColor *mdb_background;        // #25272A
@property (class, nonatomic, readonly) UIColor *mdb_surface;           // #202123, bars and sheets
@property (class, nonatomic, readonly) UIColor *mdb_surfaceRaised;     // placeholders behind images
@property (class, nonatomic, readonly) UIColor *mdb_accent;            // #FFD130
@property (class, nonatomic, readonly) UIColor *mdb_onAccent;          // text on top of the accent
@property (class, nonatomic, readonly) UIColor *mdb_textPrimary;
@property (class, nonatomic, readonly) UIColor *mdb_textSecondary;
@property (class, nonatomic, readonly) UIColor *mdb_textTertiary;
@property (class, nonatomic, readonly) UIColor *mdb_separator;
@property (class, nonatomic, readonly) UIColor *mdb_outline;
@property (class, nonatomic, readonly) UIColor *mdb_danger;
@property (class, nonatomic, readonly) UIColor *mdb_skeletonBase;
@property (class, nonatomic, readonly) UIColor *mdb_skeletonHighlight;

@end

@interface UIFont (MDBTypography)

/// System font that follows Dynamic Type, capped so fixed size cells don't explode.
+ (UIFont *)mdb_fontOfSize:(CGFloat)size weight:(UIFontWeight)weight textStyle:(UIFontTextStyle)textStyle;

@end

@interface MDBTheme : NSObject

/// Navigation bar, tab bar and other UIAppearance defaults. Call once at launch.
+ (void)applyGlobalAppearance;
/// A label already set up for Dynamic Type.
+ (UILabel *)labelWithSize:(CGFloat)size
                    weight:(UIFontWeight)weight
                 textStyle:(UIFontTextStyle)textStyle
                     color:(UIColor *)color;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
