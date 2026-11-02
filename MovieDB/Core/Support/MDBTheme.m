//
//  MDBTheme.m
//  MovieDB
//

#import "MDBTheme.h"

@implementation UIColor (MDBTheme)

+ (UIColor *)mdb_colorWithHex:(uint32_t)hex alpha:(CGFloat)alpha {
  CGFloat red = ((hex >> 16) & 0xFF) / 255.0;
  CGFloat green = ((hex >> 8) & 0xFF) / 255.0;
  CGFloat blue = (hex & 0xFF) / 255.0;
  return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)mdb_background {
  return [self mdb_colorWithHex:0x25272A alpha:1];
}
+ (UIColor *)mdb_surface {
  return [self mdb_colorWithHex:0x202123 alpha:1];
}
+ (UIColor *)mdb_surfaceRaised {
  return [self mdb_colorWithHex:0x34363A alpha:1];
}
+ (UIColor *)mdb_accent {
  return [self mdb_colorWithHex:0xFFD130 alpha:1];
}
+ (UIColor *)mdb_onAccent {
  return [self mdb_colorWithHex:0x202123 alpha:1];
}
+ (UIColor *)mdb_textPrimary {
  return [UIColor whiteColor];
}
+ (UIColor *)mdb_textSecondary {
  return [UIColor colorWithWhite:1 alpha:0.6];
}
+ (UIColor *)mdb_textTertiary {
  return [UIColor colorWithWhite:1 alpha:0.4];
}
+ (UIColor *)mdb_separator {
  return [UIColor colorWithWhite:1 alpha:0.08];
}
+ (UIColor *)mdb_outline {
  return [UIColor colorWithWhite:1 alpha:0.24];
}
+ (UIColor *)mdb_danger {
  return [self mdb_colorWithHex:0xE5484D alpha:1];
}
+ (UIColor *)mdb_skeletonBase {
  return [self mdb_colorWithHex:0x2F3134 alpha:1];
}
+ (UIColor *)mdb_skeletonHighlight {
  return [self mdb_colorWithHex:0x3A3C40 alpha:1];
}

@end

@implementation UIFont (MDBTypography)

+ (UIFont *)mdb_fontOfSize:(CGFloat)size weight:(UIFontWeight)weight textStyle:(UIFontTextStyle)textStyle {
  UIFont *base = [UIFont systemFontOfSize:size weight:weight];
  return [[UIFontMetrics metricsForTextStyle:textStyle] scaledFontForFont:base maximumPointSize:size * 1.5];
}

@end

@implementation MDBTheme

+ (void)applyGlobalAppearance {
  NSDictionary *titleAttributes = @{
    NSForegroundColorAttributeName : UIColor.mdb_textPrimary,
    NSFontAttributeName : [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold],
  };
  NSDictionary *largeTitleAttributes = @{
    NSForegroundColorAttributeName : UIColor.mdb_textPrimary,
    NSFontAttributeName : [UIFont systemFontOfSize:30 weight:UIFontWeightBold],
  };

  UINavigationBarAppearance *navigation = [[UINavigationBarAppearance alloc] init];
  [navigation configureWithOpaqueBackground];
  navigation.backgroundColor = UIColor.mdb_surface;
  navigation.shadowColor = UIColor.clearColor;
  navigation.titleTextAttributes = titleAttributes;
  navigation.largeTitleTextAttributes = largeTitleAttributes;

  UINavigationBar *navigationBar = [UINavigationBar appearance];
  navigationBar.standardAppearance = navigation;
  navigationBar.scrollEdgeAppearance = navigation;
  navigationBar.compactAppearance = navigation;
  navigationBar.compactScrollEdgeAppearance = navigation;
  navigationBar.tintColor = UIColor.mdb_textPrimary;

  UITabBarAppearance *tab = [[UITabBarAppearance alloc] init];
  [tab configureWithOpaqueBackground];
  tab.backgroundColor = UIColor.mdb_surface;
  tab.shadowColor = UIColor.mdb_separator;
  UITabBarItemAppearance *item = tab.stackedLayoutAppearance;
  item.normal.iconColor = [UIColor colorWithWhite:1 alpha:0.8];
  item.selected.iconColor = UIColor.mdb_accent;

  UITabBar *tabBar = [UITabBar appearance];
  tabBar.standardAppearance = tab;
  tabBar.scrollEdgeAppearance = tab;
  tabBar.tintColor = UIColor.mdb_accent;

  [UIRefreshControl appearance].tintColor = UIColor.mdb_accent;
  [UISearchBar appearance].tintColor = UIColor.mdb_accent;
  [UISearchBar appearance].barStyle = UIBarStyleBlack;
}

+ (UILabel *)labelWithSize:(CGFloat)size weight:(UIFontWeight)weight textStyle:(UIFontTextStyle)textStyle color:(UIColor *)color {
  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.font = [UIFont mdb_fontOfSize:size weight:weight textStyle:textStyle];
  label.adjustsFontForContentSizeCategory = YES;
  label.textColor = color;
  return label;
}

+ (UILabel *)sectionTitleLabel:(NSString *)title {
  UILabel *label = [self labelWithSize:17 weight:UIFontWeightBold textStyle:UIFontTextStyleHeadline
                                 color:UIColor.mdb_textPrimary];
  label.text = title;
  label.accessibilityTraits = UIAccessibilityTraitHeader;
  return label;
}

@end
