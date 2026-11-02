//
//  MDBMovieListCell.m
//  MovieDB
//

#import "MDBMovieListCell.h"
#import "MDBMovieCellModel.h"
#import "MDBPosterView.h"
#import "MDBTheme.h"

@interface MDBMovieListCell ()
@property (nonatomic, readonly) MDBPosterView *posterView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *metaLabel;
@property (nonatomic, readonly) UILabel *scoreLabel;
@property (nonatomic, readonly) UILabel *votesLabel;
@property (nonatomic, readonly) UIStackView *ratingRow;
@property (nonatomic, readonly) UILabel *overviewLabel;
@property (nonatomic, readonly) UIButton *favoriteButton;
@end

@implementation MDBMovieListCell

+ (NSString *)identifier {
  return @"MDBMovieListCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.backgroundColor = UIColor.clearColor;
    UIView *selected = [[UIView alloc] init];
    selected.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
    self.selectedBackgroundView = selected;

    _posterView = [[MDBPosterView alloc] initWithFrame:CGRectZero];
    _posterView.showsRating = NO;

    _titleLabel = [MDBTheme labelWithSize:15 weight:UIFontWeightSemibold textStyle:UIFontTextStyleSubheadline
                                    color:UIColor.mdb_textPrimary];
    _titleLabel.numberOfLines = 2;
    _metaLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                   color:UIColor.mdb_textSecondary];

    UIImageView *star = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"star.fill"
                              withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:10
                                                                                                weight:UIImageSymbolWeightBold]]];
    star.tintColor = UIColor.mdb_accent;
    [star setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    _scoreLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightSemibold textStyle:UIFontTextStyleCaption1
                                    color:UIColor.mdb_textPrimary];
    _votesLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                    color:UIColor.mdb_textTertiary];
    _ratingRow = [[UIStackView alloc] initWithArrangedSubviews:@[ star, _scoreLabel, _votesLabel ]];
    _ratingRow.spacing = 4;
    _ratingRow.alignment = UIStackViewAlignmentCenter;

    _overviewLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                       color:[UIColor colorWithWhite:1 alpha:0.5]];
    _overviewLabel.numberOfLines = 2;

    UIStackView *info = [[UIStackView alloc] initWithArrangedSubviews:@[ _titleLabel, _metaLabel, _ratingRow, _overviewLabel ]];
    info.translatesAutoresizingMaskIntoConstraints = NO;
    info.axis = UILayoutConstraintAxisVertical;
    info.spacing = 4;
    info.alignment = UIStackViewAlignmentFill;

    UIButtonConfiguration *heart = [UIButtonConfiguration plainButtonConfiguration];
    heart.image = [UIImage systemImageNamed:@"heart.circle.fill"
                          withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22
                                                                                            weight:UIImageSymbolWeightRegular]];
    heart.baseForegroundColor = UIColor.mdb_accent;
    heart.contentInsets = NSDirectionalEdgeInsetsMake(0, 8, 8, 0);
    _favoriteButton = [UIButton buttonWithConfiguration:heart primaryAction:nil];
    _favoriteButton.translatesAutoresizingMaskIntoConstraints = NO;
    _favoriteButton.accessibilityLabel = @"Remove from favorites";
    [_favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:_posterView];
    [self.contentView addSubview:info];
    [self.contentView addSubview:_favoriteButton];

    NSLayoutConstraint *bottom = [_posterView.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor
                                                                                    constant:-10];
    NSLayoutConstraint *infoBottom = [info.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor
                                                                                 constant:-10];
    [NSLayoutConstraint activateConstraints:@[
      [_posterView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
      [_posterView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
      [_posterView.widthAnchor constraintEqualToConstant:70],
      [_posterView.heightAnchor constraintEqualToConstant:105],
      bottom,
      [info.leadingAnchor constraintEqualToAnchor:_posterView.trailingAnchor constant:14],
      [info.topAnchor constraintEqualToAnchor:_posterView.topAnchor],
      [info.trailingAnchor constraintEqualToAnchor:_favoriteButton.leadingAnchor constant:-4],
      infoBottom,
      [_favoriteButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
      [_favoriteButton.topAnchor constraintEqualToAnchor:_posterView.topAnchor constant:-4],
      [_favoriteButton.widthAnchor constraintEqualToConstant:36],
      [_favoriteButton.heightAnchor constraintEqualToConstant:36],
    ]];
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  [self.posterView reset];
  self.onFavoriteTapped = nil;
}

- (void)configureWithModel:(MDBMovieCellModel *)model showsFavorite:(BOOL)showsFavorite {
  [self.posterView setImageURL:model.smallPosterURL];
  self.titleLabel.text = model.title;
  self.metaLabel.text = model.metaText;
  self.metaLabel.hidden = model.metaText.length == 0;
  self.scoreLabel.text = model.ratingText;
  self.votesLabel.text = model.votesText;
  self.ratingRow.hidden = model.rating <= 0;
  self.overviewLabel.text = model.overview;
  self.overviewLabel.hidden = model.overview.length == 0;
  self.favoriteButton.hidden = !showsFavorite;
  // When the heart is hidden the text can use its space.
  self.favoriteButton.alpha = showsFavorite ? 1 : 0;

  self.accessibilityLabel = model.accessibilityLabelText;
  NSMutableArray<UIAccessibilityCustomAction *> *actions = [NSMutableArray array];
  if (showsFavorite) {
    __weak typeof(self) weakSelf = self;
    UIAccessibilityCustomAction *remove = [[UIAccessibilityCustomAction alloc]
         initWithName:@"Remove from favorites" actionHandler:^BOOL(UIAccessibilityCustomAction *action) {
           [weakSelf favoriteTapped];
           return YES;
         }];
    [actions addObject:remove];
  }
  self.accessibilityCustomActions = actions;
}

- (void)favoriteTapped {
  if (self.onFavoriteTapped) {
    self.onFavoriteTapped();
  }
}

@end
