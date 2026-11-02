//
//  MDBMovieDetailViewController.m
//  MovieDB
//

#import "MDBMovieDetailViewController.h"
#import "MDBButtonFactory.h"
#import "MDBCastCell.h"
#import "MDBLog.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetailViewModel.h"
#import "MDBPosterCell.h"
#import "MDBRatingPillView.h"
#import "MDBSignpost.h"
#import "MDBStateView.h"
#import "MDBTheme.h"
#import "MDBWrapView.h"
#import <SDWebImage/SDWebImage.h>

static const CGFloat MDBHeaderHeight = 470;
static const NSUInteger MDBOverviewCollapsedLines = 4;

@interface MDBMovieDetailViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>
@property (nonatomic, readwrite) MDBMovieDetailViewModel *viewModel;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImageView *backdropView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) MDBRatingPillView *ratingPill;
@property (nonatomic) UILabel *metaLabel;
@property (nonatomic) MDBWrapView *genreWrap;
@property (nonatomic) UIButton *trailerButton;
@property (nonatomic) UIButton *favoriteButton;
@property (nonatomic) UILabel *taglineLabel;
@property (nonatomic) UILabel *overviewLabel;
@property (nonatomic) UIButton *readMoreButton;
@property (nonatomic) UIStackView *factsStack;
@property (nonatomic) UIView *factsBox;
@property (nonatomic) UIStackView *castSection;
@property (nonatomic) UICollectionView *castView;
@property (nonatomic) UIStackView *moreSection;
@property (nonatomic) UICollectionView *moreView;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) MDBStateView *stateView;
@property (nonatomic) BOOL overviewExpanded;
@property (nonatomic, copy) NSArray<MDBCastCellModel *> *castItems;
@property (nonatomic, copy) NSArray<MDBMovieCellModel *> *moreItems;
@property (nonatomic, copy) NSArray<NSString *> *renderedGenres;
@property (nonatomic) os_signpost_id_t loadSignpost;
@property (nonatomic) BOOL hasFinishedFirstLoad;
@end

@implementation MDBMovieDetailViewController

- (instancetype)initWithViewModel:(MDBMovieDetailViewModel *)viewModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = viewModel;
        _renderedGenres = @[];
        _castItems = @[];
        _moreItems = @[];
    }
    return self;
}

- (void)dealloc {
    MDBLogDebug(MDBLogCategoryUI, @"Detail for %ld released", (long)_viewModel.movieID);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadSignpost = [MDBSignpost beginScreenLoad:@"Movie Detail"];
    self.view.backgroundColor = UIColor.mdb_background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.up"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(shareTapped:)];
    share.accessibilityLabel = @"Share";
    self.navigationItem.rightBarButtonItem = share;
    [self applyNavigationBarTransparent:YES];

    [self buildLayout];

    __weak typeof(self) weakSelf = self;
    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self render];
    [self.viewModel load];
}

#pragma mark - Navigation bar

- (void)applyNavigationBarTransparent:(BOOL)transparent {
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    if (transparent) {
        [appearance configureWithTransparentBackground];
    } else {
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = UIColor.mdb_surface;
        appearance.shadowColor = UIColor.clearColor;
    }
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.mdb_textPrimary};
    self.navigationItem.standardAppearance = appearance;
    self.navigationItem.scrollEdgeAppearance = appearance;
    self.navigationItem.compactAppearance = appearance;
    self.navigationItem.title = transparent ? @"" : self.viewModel.title;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.scrollView) {
        return;
    }
    BOOL pastHeader = scrollView.contentOffset.y > MDBHeaderHeight - 140;
    BOOL isTransparent = self.navigationItem.title.length == 0;
    if (pastHeader == isTransparent) {
        [self applyNavigationBarTransparent:!pastHeader];
    }
}

#pragma mark - Layout

- (void)buildLayout {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.scrollView.delegate = self;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    UIStackView *content = [[UIStackView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    [self.scrollView addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],
    ]];

    [content addArrangedSubview:[self makeHeader]];

    // The body has no side margins so the cast and poster rows can scroll edge to edge.
    // Everything else gets 20 pt of padding through padded:.
    UIStackView *body = [[UIStackView alloc] init];
    body.axis = UILayoutConstraintAxisVertical;
    body.spacing = 28;
    body.layoutMarginsRelativeArrangement = YES;
    body.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(20, 0, 40, 0);
    [content addArrangedSubview:body];

    [body addArrangedSubview:[self padded:[self makeActions]]];
    [body addArrangedSubview:[self padded:[self makeStoryline]]];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.color = UIColor.mdb_accent;
    self.spinner.hidesWhenStopped = YES;
    [body addArrangedSubview:self.spinner];

    self.stateView = [[MDBStateView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    self.stateView.onAction = ^{
        [weakSelf.viewModel load];
    };
    [self.stateView.heightAnchor constraintEqualToConstant:320].active = YES;
    [body addArrangedSubview:self.stateView];

    UIView *facts = [self padded:[self makeFacts]];
    [body addArrangedSubview:facts];
    self.factsBox = facts;
    [body addArrangedSubview:[self makeCastSection]];
    [body addArrangedSubview:[self makeMoreSection]];
}

- (UIView *)padded:(UIView *)view {
    UIView *container = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:view];
    [NSLayoutConstraint activateConstraints:@[
        [view.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20],
        [view.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20],
        [view.topAnchor constraintEqualToAnchor:container.topAnchor],
        [view.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
    ]];
    return container;
}

- (UIView *)makeHeader {
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.clipsToBounds = YES;
    [header.heightAnchor constraintEqualToConstant:MDBHeaderHeight].active = YES;

    self.backdropView = [[UIImageView alloc] init];
    self.backdropView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backdropView.contentMode = UIViewContentModeScaleAspectFill;
    self.backdropView.backgroundColor = UIColor.mdb_surfaceRaised;
    self.backdropView.sd_imageTransition = SDWebImageTransition.fadeTransition;
    self.backdropView.accessibilityIgnoresInvertColors = YES;
    [header addSubview:self.backdropView];

    UIView *topScrim = [self gradientViewFromColor:[UIColor colorWithWhite:0 alpha:0.7]
                                           toColor:[UIColor colorWithWhite:0 alpha:0]
                                         locations:@[@0, @1]
                                            height:140];
    UIView *bottomScrim = [self gradientViewFromColor:[UIColor.mdb_background colorWithAlphaComponent:0]
                                              toColor:UIColor.mdb_background
                                            locations:@[@0.3, @0.95]
                                               height:MDBHeaderHeight];
    [header addSubview:topScrim];
    [header addSubview:bottomScrim];

    self.titleLabel = [MDBTheme labelWithSize:28 weight:UIFontWeightBold textStyle:UIFontTextStyleTitle1 color:UIColor.mdb_textPrimary];
    self.titleLabel.numberOfLines = 3;
    self.titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;

    self.ratingPill = [[MDBRatingPillView alloc] initWithFrame:CGRectZero];
    self.metaLabel = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote color:[UIColor colorWithWhite:1 alpha:0.75]];
    UIStackView *metaRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.ratingPill, self.metaLabel]];
    metaRow.spacing = 8;
    metaRow.alignment = UIStackViewAlignmentCenter;

    self.genreWrap = [[MDBWrapView alloc] initWithFrame:CGRectZero];
    self.genreWrap.horizontalSpacing = 6;
    self.genreWrap.verticalSpacing = 6;

    UIStackView *info = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleLabel, metaRow, self.genreWrap]];
    info.translatesAutoresizingMaskIntoConstraints = NO;
    info.axis = UILayoutConstraintAxisVertical;
    info.spacing = 10;
    info.alignment = UIStackViewAlignmentFill;
    [header addSubview:info];

    [NSLayoutConstraint activateConstraints:@[
        [self.backdropView.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [self.backdropView.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [self.backdropView.topAnchor constraintEqualToAnchor:header.topAnchor],
        [self.backdropView.bottomAnchor constraintEqualToAnchor:header.bottomAnchor],
        [topScrim.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [topScrim.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [topScrim.topAnchor constraintEqualToAnchor:header.topAnchor],
        [topScrim.heightAnchor constraintEqualToConstant:140],
        [bottomScrim.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [bottomScrim.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [bottomScrim.topAnchor constraintEqualToAnchor:header.topAnchor],
        [bottomScrim.bottomAnchor constraintEqualToAnchor:header.bottomAnchor],
        [info.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [info.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [info.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-8],
    ]];
    return header;
}

- (UIView *)gradientViewFromColor:(UIColor *)from
                          toColor:(UIColor *)to
                        locations:(NSArray<NSNumber *> *)locations
                           height:(CGFloat)height {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.userInteractionEnabled = NO;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(id)from.CGColor, (id)to.CGColor];
    gradient.locations = locations;
    // Wider than any iPhone and as tall as the view, so the layer never needs resizing.
    gradient.frame = CGRectMake(0, 0, 1000, height);
    [view.layer addSublayer:gradient];
    view.clipsToBounds = YES;
    return view;
}

- (UIView *)makeActions {
    self.trailerButton = [MDBButtonFactory buttonWithStyle:MDBButtonStylePrimary title:@"Watch Trailer" symbolName:@"play.fill"];
    [self.trailerButton addTarget:self action:@selector(trailerTapped) forControlEvents:UIControlEventTouchUpInside];
    self.favoriteButton = [MDBButtonFactory buttonWithStyle:MDBButtonStyleSecondary title:@"Add to Favorite" symbolName:@"plus"];
    [self.favoriteButton addTarget:self action:@selector(favoriteTapped) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[self.trailerButton, self.favoriteButton]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 12;
    [row.heightAnchor constraintGreaterThanOrEqualToConstant:42].active = YES;
    return row;
}

- (UIView *)makeStoryline {
    UILabel *title = [MDBTheme labelWithSize:17 weight:UIFontWeightBold textStyle:UIFontTextStyleHeadline color:UIColor.mdb_textPrimary];
    title.text = @"Storyline";
    title.accessibilityTraits = UIAccessibilityTraitHeader;

    self.taglineLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightMedium textStyle:UIFontTextStyleSubheadline color:UIColor.mdb_accent];
    self.taglineLabel.numberOfLines = 0;

    self.overviewLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleBody color:[UIColor colorWithWhite:1 alpha:0.75]];
    self.overviewLabel.numberOfLines = MDBOverviewCollapsedLines;

    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.contentInsets = NSDirectionalEdgeInsetsZero;
    configuration.baseForegroundColor = UIColor.mdb_accent;
    self.readMoreButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    [self.readMoreButton addTarget:self action:@selector(readMoreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self updateReadMoreTitle];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, self.taglineLabel, self.overviewLabel, self.readMoreButton]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.spacing = 10;
    [stack setCustomSpacing:6 afterView:self.overviewLabel];
    [self.overviewLabel.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
    [self.taglineLabel.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
    return stack;
}

- (UIView *)makeFacts {
    self.factsStack = [[UIStackView alloc] init];
    self.factsStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.factsStack.distribution = UIStackViewDistributionFillEqually;
    self.factsBox = [[UIView alloc] init];
    self.factsBox.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
    self.factsBox.layer.cornerRadius = 10;
    [self.factsBox addSubview:self.factsStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.factsStack.leadingAnchor constraintEqualToAnchor:self.factsBox.leadingAnchor constant:8],
        [self.factsStack.trailingAnchor constraintEqualToAnchor:self.factsBox.trailingAnchor constant:-8],
        [self.factsStack.topAnchor constraintEqualToAnchor:self.factsBox.topAnchor constant:14],
        [self.factsStack.bottomAnchor constraintEqualToAnchor:self.factsBox.bottomAnchor constant:-14],
    ]];
    return self.factsBox;
}

- (UICollectionView *)horizontalCollectionWithItemSize:(CGSize)itemSize spacing:(CGFloat)spacing cellClass:(Class)cellClass identifier:(NSString *)identifier {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = itemSize;
    layout.minimumLineSpacing = spacing;
    layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    collectionView.backgroundColor = UIColor.clearColor;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    [collectionView.heightAnchor constraintEqualToConstant:itemSize.height].active = YES;
    return collectionView;
}

- (UIStackView *)sectionWithTitle:(NSString *)title collection:(UICollectionView *)collection {
    UILabel *label = [MDBTheme labelWithSize:17 weight:UIFontWeightBold textStyle:UIFontTextStyleHeadline color:UIColor.mdb_textPrimary];
    label.text = title;
    label.accessibilityTraits = UIAccessibilityTraitHeader;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[[self padded:label], collection]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    return stack;
}

- (UIView *)makeCastSection {
    self.castView = [self horizontalCollectionWithItemSize:CGSizeMake(80, 124) spacing:12 cellClass:[MDBCastCell class] identifier:MDBCastCell.identifier];
    self.castSection = [self sectionWithTitle:@"Cast" collection:self.castView];
    return self.castSection;
}

- (UIView *)makeMoreSection {
    self.moreView = [self horizontalCollectionWithItemSize:CGSizeMake(102, 153) spacing:8 cellClass:[MDBPosterCell class] identifier:MDBPosterCell.identifier];
    self.moreSection = [self sectionWithTitle:@"More Like This" collection:self.moreView];
    return self.moreSection;
}

#pragma mark - Rendering

- (void)render {
    MDBMovieDetailViewModel *viewModel = self.viewModel;
    MDBLoadState state = viewModel.state;

    [self.backdropView sd_setImageWithURL:viewModel.backdropURL placeholderImage:nil options:SDWebImageRetryFailed];
    self.titleLabel.text = viewModel.title;
    [self.ratingPill setRatingText:viewModel.ratingText];
    self.metaLabel.text = viewModel.metaText;

    if (![viewModel.genreNames isEqualToArray:self.renderedGenres]) {
        self.renderedGenres = viewModel.genreNames;
        NSMutableArray<UIView *> *chips = [NSMutableArray array];
        for (NSString *name in viewModel.genreNames) {
            UIButton *chip = [MDBButtonFactory chipWithTitle:name];
            chip.userInteractionEnabled = NO;
            [chips addObject:chip];
        }
        [self.genreWrap setItemViews:chips];
    }

    self.taglineLabel.text = viewModel.tagline;
    self.taglineLabel.hidden = viewModel.tagline.length == 0;
    self.overviewLabel.text = viewModel.overview;
    self.readMoreButton.hidden = viewModel.overview.length < 220;

    BOOL loaded = state == MDBLoadStateLoaded;
    self.trailerButton.enabled = viewModel.hasTrailer;
    self.trailerButton.configuration = [MDBButtonFactory configurationWithStyle:MDBButtonStylePrimary
                                                                          title:loaded && !viewModel.hasTrailer ? @"No Trailer" : @"Watch Trailer"
                                                                     symbolName:@"play.fill"];
    self.favoriteButton.configuration = viewModel.isFavorite
        ? [MDBButtonFactory configurationWithStyle:MDBButtonStyleFavorited title:@"Favorited" symbolName:@"heart.fill"]
        : [MDBButtonFactory configurationWithStyle:MDBButtonStyleSecondary title:@"Add to Favorite" symbolName:@"plus"];
    self.favoriteButton.accessibilityValue = viewModel.isFavorite ? @"Saved" : @"Not saved";

    if (state == MDBLoadStateLoading && !viewModel.detail) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
    self.stateView.hidden = state != MDBLoadStateFailed;
    NSError *error = viewModel.error;
    if (state == MDBLoadStateFailed && error) {
        [self.stateView configureWithError:error];
    }

    [self renderFacts];
    self.factsBox.hidden = viewModel.facts.count == 0;
    self.castItems = viewModel.cast;
    self.moreItems = viewModel.recommendations;
    self.castSection.hidden = self.castItems.count == 0;
    self.moreSection.hidden = self.moreItems.count == 0;
    [self.castView reloadData];
    [self.moreView reloadData];

    if (!self.hasFinishedFirstLoad && (state == MDBLoadStateLoaded || state == MDBLoadStateFailed)) {
        self.hasFinishedFirstLoad = YES;
        [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Movie Detail"];
    }
}

- (void)renderFacts {
    for (UIView *view in self.factsStack.arrangedSubviews) {
        [view removeFromSuperview];
    }
    for (MDBMovieFact *fact in self.viewModel.facts) {
        UILabel *title = [MDBTheme labelWithSize:11 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption2 color:UIColor.mdb_textSecondary];
        title.text = fact.title;
        title.textAlignment = NSTextAlignmentCenter;
        UILabel *value = [MDBTheme labelWithSize:13 weight:UIFontWeightSemibold textStyle:UIFontTextStyleFootnote color:UIColor.mdb_textPrimary];
        value.text = fact.value;
        value.textAlignment = NSTextAlignmentCenter;
        value.numberOfLines = 2;
        UIStackView *column = [[UIStackView alloc] initWithArrangedSubviews:@[title, value]];
        column.axis = UILayoutConstraintAxisVertical;
        column.spacing = 4;
        column.isAccessibilityElement = YES;
        column.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", fact.title, fact.value];
        [self.factsStack addArrangedSubview:column];
    }
}

- (void)updateReadMoreTitle {
    UIButtonConfiguration *configuration = self.readMoreButton.configuration;
    configuration.attributedTitle = [[NSAttributedString alloc] initWithString:self.overviewExpanded ? @"Show less" : @"Read more" attributes:@{
        NSFontAttributeName: [UIFont mdb_fontOfSize:13 weight:UIFontWeightSemibold textStyle:UIFontTextStyleFootnote],
        NSForegroundColorAttributeName: UIColor.mdb_accent,
    }];
    self.readMoreButton.configuration = configuration;
}

#pragma mark - Actions

- (void)trailerTapped {
    if (self.viewModel.hasTrailer) {
        [self.delegate movieDetailViewController:self didRequestTrailers:self.viewModel.videos movieTitle:self.viewModel.title];
    }
}

- (void)favoriteTapped {
    [self.viewModel toggleFavorite];
    UINotificationFeedbackGenerator *haptic = [[UINotificationFeedbackGenerator alloc] init];
    [haptic notificationOccurred:UINotificationFeedbackTypeSuccess];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    self.viewModel.isFavorite ? @"Added to favorites" : @"Removed from favorites");
}

- (void)readMoreTapped {
    self.overviewExpanded = !self.overviewExpanded;
    self.overviewLabel.numberOfLines = self.overviewExpanded ? 0 : MDBOverviewCollapsedLines;
    [self updateReadMoreTitle];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)shareTapped:(UIBarButtonItem *)sender {
    NSURL *url = self.viewModel.shareURL;
    if (!url) {
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[self.viewModel.title, url]
                                                                           applicationActivities:nil];
    activity.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activity animated:YES completion:nil];
}

#pragma mark - Collections

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return collectionView == self.castView ? (NSInteger)self.castItems.count : (NSInteger)self.moreItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.castView) {
        MDBCastCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBCastCell.identifier forIndexPath:indexPath];
        [cell configureWithModel:self.castItems[(NSUInteger)indexPath.item]];
        return cell;
    }
    MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
    [cell configureWithModel:self.moreItems[(NSUInteger)indexPath.item] style:MDBPosterCellStylePlain];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    id<MDBMovieDetailViewControllerDelegate> delegate = self.delegate;
    if (collectionView == self.castView) {
        [delegate movieDetailViewController:self didSelectCastMember:self.castItems[(NSUInteger)indexPath.item]];
    } else {
        [delegate movieDetailViewController:self didSelectMovie:self.moreItems[(NSUInteger)indexPath.item]];
    }
}

@end
