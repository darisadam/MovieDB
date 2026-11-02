//
//  MDBButtonFactory.m
//  MovieDB
//

#import "MDBButtonFactory.h"
#import "MDBTheme.h"

@implementation MDBButtonFactory

+ (UIButtonConfiguration *)configurationWithStyle:(MDBButtonStyle)style
                                            title:(NSString *)title
                                       symbolName:(nullable NSString *)symbolName {
    UIButtonConfiguration *configuration = nil;
    UIColor *foreground = nil;
    UIColor *iconColor = nil;
    switch (style) {
        case MDBButtonStylePrimary:
            configuration = [UIButtonConfiguration filledButtonConfiguration];
            configuration.baseBackgroundColor = UIColor.mdb_accent;
            foreground = UIColor.mdb_onAccent;
            iconColor = UIColor.mdb_onAccent;
            break;
        case MDBButtonStyleSecondary:
            configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.background.strokeColor = UIColor.mdb_outline;
            configuration.background.strokeWidth = 1;
            foreground = UIColor.mdb_textPrimary;
            iconColor = UIColor.mdb_accent;
            break;
        case MDBButtonStyleFavorited:
            configuration = [UIButtonConfiguration plainButtonConfiguration];
            configuration.background.backgroundColor = [UIColor.mdb_accent colorWithAlphaComponent:0.14];
            configuration.background.strokeColor = [UIColor.mdb_accent colorWithAlphaComponent:0.6];
            configuration.background.strokeWidth = 1;
            foreground = UIColor.mdb_accent;
            iconColor = UIColor.mdb_accent;
            break;
    }
    configuration.background.cornerRadius = 6;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleFixed;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(10, 14, 10, 14);
    configuration.imagePadding = 8;
    configuration.baseForegroundColor = foreground;

    UIFont *font = [UIFont mdb_fontOfSize:14 weight:UIFontWeightSemibold textStyle:UIFontTextStyleSubheadline];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: foreground,
    }];
    configuration.attributedTitle = attributedTitle;

    NSString *symbol = symbolName;
    if (symbol.length > 0) {
        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightSemibold];
        UIImage *image = [[UIImage systemImageNamed:symbol withConfiguration:symbolConfig] imageWithTintColor:iconColor
                                                                                                renderingMode:UIImageRenderingModeAlwaysOriginal];
        configuration.image = image;
    }
    return configuration;
}

+ (UIButton *)buttonWithStyle:(MDBButtonStyle)style title:(NSString *)title symbolName:(nullable NSString *)symbolName {
    UIButton *button = [UIButton buttonWithConfiguration:[self configurationWithStyle:style title:title symbolName:symbolName]
                                           primaryAction:nil];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.adjustsFontForContentSizeCategory = YES;
    return button;
}

+ (UIButton *)chipWithTitle:(NSString *)title {
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(7, 14, 7, 14);
    UIButton *chip = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    chip.translatesAutoresizingMaskIntoConstraints = NO;
    chip.configurationUpdateHandler = ^(UIButton *button) {
        UIButtonConfiguration *updated = button.configuration;
        BOOL isOn = button.isSelected;
        UIColor *textColor = isOn ? UIColor.mdb_onAccent : [UIColor colorWithWhite:1 alpha:0.85];
        UIFont *font = [UIFont mdb_fontOfSize:13 weight:isOn ? UIFontWeightSemibold : UIFontWeightMedium
                                    textStyle:UIFontTextStyleFootnote];
        updated.attributedTitle = [[NSAttributedString alloc] initWithString:updated.title ?: @"" attributes:@{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor,
        }];
        updated.background.backgroundColor = isOn ? UIColor.mdb_accent : [UIColor colorWithWhite:1 alpha:0.04];
        updated.background.strokeColor = isOn ? UIColor.clearColor : UIColor.mdb_outline;
        updated.background.strokeWidth = 1;
        button.configuration = updated;
    };
    return chip;
}

+ (void)setChip:(UIButton *)chip selected:(BOOL)selected {
    chip.selected = selected;
    chip.accessibilityTraits = selected ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
    [chip setNeedsUpdateConfiguration];
}

@end
