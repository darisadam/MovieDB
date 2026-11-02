//
//  MDBListRowButton.m
//  MovieDB
//

#import "MDBListRowButton.h"
#import "MDBTheme.h"

@interface MDBListRowButton ()
@property (nonatomic) UIImageView *iconView;
@property (nonatomic) UILabel *rowTitleLabel;
@property (nonatomic) UILabel *valueLabel;
@property (nonatomic) UIImageView *chevronView;
@end

@implementation MDBListRowButton

+ (instancetype)rowWithSymbolName:(NSString *)symbolName title:(NSString *)title {
  MDBListRowButton *row = [self buttonWithType:UIButtonTypeCustom];
  [row setUpWithSymbolName:symbolName title:title];
  return row;
}

- (void)setUpWithSymbolName:(NSString *)symbolName title:(NSString *)title {
  self.translatesAutoresizingMaskIntoConstraints = NO;

  self.iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:symbolName]];
  self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
  self.iconView.tintColor = UIColor.mdb_accent;
  self.iconView.contentMode = UIViewContentModeScaleAspectFit;

  self.rowTitleLabel = [MDBTheme labelWithSize:15 weight:UIFontWeightRegular textStyle:UIFontTextStyleBody
                                         color:UIColor.mdb_textPrimary];
  self.rowTitleLabel.text = title;
  self.valueLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleSubheadline
                                      color:UIColor.mdb_textSecondary];
  [self.valueLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

  self.chevronView = [[UIImageView alloc]
      initWithImage:[UIImage
                         systemImageNamed:@"chevron.right"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:13
                                                                                          weight:UIImageSymbolWeightSemibold]]];
  self.chevronView.translatesAutoresizingMaskIntoConstraints = NO;
  self.chevronView.tintColor = UIColor.mdb_textTertiary;
  self.showsChevron = YES;

  UIView *divider = [[UIView alloc] init];
  divider.translatesAutoresizingMaskIntoConstraints = NO;
  divider.backgroundColor = UIColor.mdb_separator;
  divider.userInteractionEnabled = NO;

  for (UIView *view in @[ self.iconView, self.rowTitleLabel, self.valueLabel, self.chevronView, divider ]) {
    view.userInteractionEnabled = NO;
    [self addSubview:view];
  }

  [NSLayoutConstraint activateConstraints:@[
    [self.heightAnchor constraintGreaterThanOrEqualToConstant:52],
    [self.iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [self.iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.iconView.widthAnchor constraintEqualToConstant:22],
    [self.iconView.heightAnchor constraintEqualToConstant:22],
    [self.rowTitleLabel.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:14],
    [self.rowTitleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.rowTitleLabel.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor constant:12],
    [self.valueLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.rowTitleLabel.trailingAnchor constant:8],
    [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.chevronView.leadingAnchor constant:-8],
    [self.valueLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.chevronView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [self.chevronView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [divider.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [divider.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    [divider.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [divider.heightAnchor constraintEqualToConstant:1],
  ]];
  [self updateAccessibility];
}

- (void)setValueText:(nullable NSString *)valueText {
  _valueText = [valueText copy];
  self.valueLabel.text = _valueText;
  [self updateAccessibility];
}

- (void)setShowsChevron:(BOOL)showsChevron {
  _showsChevron = showsChevron;
  self.chevronView.hidden = !showsChevron;
}

- (void)setDestructive:(BOOL)destructive {
  _destructive = destructive;
  UIColor *color = destructive ? UIColor.mdb_danger : UIColor.mdb_textPrimary;
  self.rowTitleLabel.textColor = color;
  self.iconView.tintColor = destructive ? UIColor.mdb_danger : UIColor.mdb_accent;
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  self.alpha = highlighted ? 0.6 : 1.0;
}

- (void)updateAccessibility {
  self.isAccessibilityElement = YES;
  self.accessibilityLabel = self.rowTitleLabel.text;
  self.accessibilityValue = self.valueText;
  self.accessibilityTraits = UIAccessibilityTraitButton;
}

@end
