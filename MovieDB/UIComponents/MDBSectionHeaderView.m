//
//  MDBSectionHeaderView.m
//  MovieDB
//

#import "MDBSectionHeaderView.h"
#import "MDBTheme.h"

@interface MDBSectionHeaderView ()
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UIButton *seeAllButton;
@end

@implementation MDBSectionHeaderView

+ (NSString *)identifier {
  return @"MDBSectionHeaderView";
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _titleLabel = [MDBTheme labelWithSize:17 weight:UIFontWeightBold textStyle:UIFontTextStyleHeadline
                                    color:UIColor.mdb_textPrimary];
    _titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;

    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.attributedTitle = [[NSAttributedString alloc] initWithString:@"See All" attributes:@{
      NSFontAttributeName : [UIFont mdb_fontOfSize:13 weight:UIFontWeightMedium textStyle:UIFontTextStyleFootnote],
      NSForegroundColorAttributeName : UIColor.mdb_accent,
    }];
    configuration.image =
        [UIImage systemImageNamed:@"chevron.right"
                withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold]];
    configuration.imagePlacement = NSDirectionalRectEdgeTrailing;
    configuration.imagePadding = 3;
    configuration.baseForegroundColor = UIColor.mdb_accent;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(6, 8, 6, 0);
    _seeAllButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    _seeAllButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_seeAllButton addTarget:self action:@selector(seeAllTapped) forControlEvents:UIControlEventTouchUpInside];
    [_seeAllButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    [self addSubview:_titleLabel];
    [self addSubview:_seeAllButton];
    [NSLayoutConstraint activateConstraints:@[
      [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
      [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
      [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_seeAllButton.leadingAnchor constant:-8],
      [_seeAllButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
      [_seeAllButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.onSeeAll = nil;
}

- (void)configureWithTitle:(NSString *)title showsSeeAll:(BOOL)showsSeeAll {
  self.titleLabel.text = title;
  self.seeAllButton.hidden = !showsSeeAll;
  self.seeAllButton.accessibilityLabel = [NSString stringWithFormat:@"See all %@", title];
}

- (void)seeAllTapped {
  if (self.onSeeAll) {
    self.onSeeAll();
  }
}

@end
