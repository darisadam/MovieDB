//
//  MDBPersonViewController.m
//  MovieDB
//

#import "MDBPersonViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPersonViewModel.h"
#import "MDBPosterCell.h"
#import "MDBScreenState.h"
#import "MDBSignpost.h"
#import "MDBStateView.h"
#import "MDBTheme.h"
#import "UIView+MDBLayout.h"

@interface MDBPersonViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) MDBPersonViewModel *viewModel;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic) UIView *biographySection;
@property (nonatomic) UIImageView *profileView;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *departmentLabel;
@property (nonatomic) UIStackView *factsStack;
@property (nonatomic) UILabel *biographyLabel;
@property (nonatomic) UIButton *readMoreButton;
@property (nonatomic) UIStackView *knownForSection;
@property (nonatomic) UICollectionView *knownForView;
@property (nonatomic) UIStackView *filmographySection;
@property (nonatomic) UIStackView *filmographyRows;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) MDBStateView *stateView;
@property (nonatomic) UIStackView *content;
@property (nonatomic) BOOL biographyExpanded;
@property (nonatomic, copy) NSArray<MDBMovieCellModel *> *knownForItems;
@property (nonatomic, copy) NSArray<MDBFilmographyRow *> *filmographyItems;
@property (nonatomic) os_signpost_id_t loadSignpost;
@property (nonatomic) BOOL hasFinishedFirstLoad;
@end

@implementation MDBPersonViewController

- (instancetype)initWithViewModel:(MDBPersonViewModel *)viewModel {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    _bag = [[MDBDisposeBag alloc] init];
    _knownForItems = @[];
    _filmographyItems = @[];
    self.title = @"Cast";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.loadSignpost = [MDBSignpost beginScreenLoad:@"Person"];
  self.view.backgroundColor = UIColor.mdb_background;
  self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
  self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;

  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.alwaysBounceVertical = YES;
  [self.view addSubview:scrollView];
  [scrollView mdb_pinToEdgesOfView:self.view];

  self.content = [[UIStackView alloc] init];
  self.content.translatesAutoresizingMaskIntoConstraints = NO;
  self.content.axis = UILayoutConstraintAxisVertical;
  self.content.spacing = 28;
  [scrollView addSubview:self.content];

  [NSLayoutConstraint activateConstraints:@[
    [self.content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
    [self.content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
    [self.content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:20],
    [self.content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-40],
    [self.content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
  ]];

  [self.content addArrangedSubview:[[self makeHeader] mdb_wrappedWithHorizontalInset:20]];

  self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  self.spinner.color = UIColor.mdb_accent;
  self.spinner.hidesWhenStopped = YES;
  [self.content addArrangedSubview:self.spinner];

  self.stateView = [[MDBStateView alloc] initWithFrame:CGRectZero];
  [self.stateView.heightAnchor constraintEqualToConstant:320].active = YES;
  __weak typeof(self) weakSelf = self;
  self.stateView.onAction = ^{
    [weakSelf.viewModel load];
  };
  [self.content addArrangedSubview:self.stateView];

  self.biographySection = [[self makeBiography] mdb_wrappedWithHorizontalInset:20];
  [self.content addArrangedSubview:self.biographySection];
  [self.content addArrangedSubview:[self makeKnownFor]];
  [self.content addArrangedSubview:[[self makeFilmography] mdb_wrappedWithHorizontalInset:20]];

  [self.bag addDisposable:[self.viewModel.state subscribe:^(MDBScreenState<MDBPersonContent *> *state) {
              [weakSelf render:state];
            }]];
  [self.viewModel load];
}

#pragma mark - Building

- (UIView *)makeHeader {
  self.profileView = [[UIImageView alloc] init];
  self.profileView.translatesAutoresizingMaskIntoConstraints = NO;
  self.profileView.contentMode = UIViewContentModeScaleAspectFill;
  self.profileView.clipsToBounds = YES;
  self.profileView.layer.cornerRadius = 10;
  self.profileView.backgroundColor = UIColor.mdb_surfaceRaised;
  self.profileView.tintColor = [UIColor colorWithWhite:1 alpha:0.25];
  self.profileView.sd_imageTransition = SDWebImageTransition.fadeTransition;
  [NSLayoutConstraint activateConstraints:@[
    [self.profileView.widthAnchor constraintEqualToConstant:110],
    [self.profileView.heightAnchor constraintEqualToConstant:150],
  ]];

  self.nameLabel = [MDBTheme labelWithSize:22 weight:UIFontWeightBold textStyle:UIFontTextStyleTitle2
                                     color:UIColor.mdb_textPrimary];
  self.nameLabel.numberOfLines = 2;
  self.nameLabel.accessibilityTraits = UIAccessibilityTraitHeader;
  self.departmentLabel = [MDBTheme labelWithSize:13 weight:UIFontWeightMedium textStyle:UIFontTextStyleFootnote
                                           color:UIColor.mdb_accent];
  self.factsStack = [[UIStackView alloc] init];
  self.factsStack.axis = UILayoutConstraintAxisVertical;
  self.factsStack.spacing = 6;

  UIStackView *info = [[UIStackView alloc] initWithArrangedSubviews:@[ self.nameLabel, self.departmentLabel, self.factsStack ]];
  info.axis = UILayoutConstraintAxisVertical;
  info.spacing = 6;
  [info setCustomSpacing:10 afterView:self.departmentLabel];

  UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ self.profileView, info ]];
  row.spacing = 16;
  row.alignment = UIStackViewAlignmentTop;
  return row;
}

- (UIView *)makeBiography {
  self.biographyLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleBody
                                          color:[UIColor colorWithWhite:1 alpha:0.75]];
  self.biographyLabel.numberOfLines = 4;

  UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
  configuration.contentInsets = NSDirectionalEdgeInsetsZero;
  configuration.baseForegroundColor = UIColor.mdb_accent;
  configuration.title = @"Read more";
  self.readMoreButton = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
  [self.readMoreButton addTarget:self action:@selector(readMoreTapped) forControlEvents:UIControlEventTouchUpInside];

  UIStackView *stack = [[UIStackView alloc]
      initWithArrangedSubviews:@[ [MDBTheme sectionTitleLabel:@"Biography"], self.biographyLabel, self.readMoreButton ]];
  stack.axis = UILayoutConstraintAxisVertical;
  stack.alignment = UIStackViewAlignmentLeading;
  stack.spacing = 10;
  [self.biographyLabel.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
  return stack;
}

- (UIView *)makeKnownFor {
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.itemSize = CGSizeMake(105, 200);
  layout.minimumLineSpacing = 10;
  layout.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20);
  self.knownForView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.knownForView.backgroundColor = UIColor.clearColor;
  self.knownForView.showsHorizontalScrollIndicator = NO;
  self.knownForView.dataSource = self;
  self.knownForView.delegate = self;
  [self.knownForView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
  [self.knownForView.heightAnchor constraintEqualToConstant:200].active = YES;

  self.knownForSection = [[UIStackView alloc] initWithArrangedSubviews:@[
    [[MDBTheme sectionTitleLabel:@"Known For"] mdb_wrappedWithHorizontalInset:20], self.knownForView
  ]];
  self.knownForSection.axis = UILayoutConstraintAxisVertical;
  self.knownForSection.spacing = 12;
  return self.knownForSection;
}

- (UIView *)makeFilmography {
  self.filmographyRows = [[UIStackView alloc] init];
  self.filmographyRows.axis = UILayoutConstraintAxisVertical;
  self.filmographySection =
      [[UIStackView alloc] initWithArrangedSubviews:@[ [MDBTheme sectionTitleLabel:@"Filmography"], self.filmographyRows ]];
  self.filmographySection.axis = UILayoutConstraintAxisVertical;
  self.filmographySection.spacing = 8;
  return self.filmographySection;
}

- (UIControl *)filmographyRowViewForRow:(MDBFilmographyRow *)row index:(NSInteger)index {
  UIControl *control = [[UIControl alloc] init];
  control.tag = index;
  [control addTarget:self action:@selector(filmographyTapped:) forControlEvents:UIControlEventTouchUpInside];

  UILabel *year = [MDBTheme labelWithSize:13 weight:UIFontWeightSemibold textStyle:UIFontTextStyleFootnote
                                    color:UIColor.mdb_accent];
  year.text = row.yearText;
  [year setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  [year.widthAnchor constraintGreaterThanOrEqualToConstant:36].active = YES;

  UILabel *title = [MDBTheme labelWithSize:14 weight:UIFontWeightMedium textStyle:UIFontTextStyleSubheadline
                                     color:UIColor.mdb_textPrimary];
  title.text = row.title;
  UILabel *role = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                    color:UIColor.mdb_textSecondary];
  role.text = row.roleText;
  role.hidden = row.roleText.length == 0;

  UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[ title, role ]];
  text.axis = UILayoutConstraintAxisVertical;
  text.spacing = 2;
  UIStackView *line = [[UIStackView alloc] initWithArrangedSubviews:@[ year, text ]];
  line.translatesAutoresizingMaskIntoConstraints = NO;
  line.spacing = 14;
  line.alignment = UIStackViewAlignmentCenter;
  line.userInteractionEnabled = NO;

  UIView *divider = [[UIView alloc] init];
  divider.translatesAutoresizingMaskIntoConstraints = NO;
  divider.backgroundColor = UIColor.mdb_separator;
  divider.userInteractionEnabled = NO;

  [control addSubview:line];
  [control addSubview:divider];
  [NSLayoutConstraint activateConstraints:@[
    [line.leadingAnchor constraintEqualToAnchor:control.leadingAnchor],
    [line.trailingAnchor constraintEqualToAnchor:control.trailingAnchor],
    [line.topAnchor constraintEqualToAnchor:control.topAnchor constant:12],
    [line.bottomAnchor constraintEqualToAnchor:control.bottomAnchor constant:-12],
    [divider.leadingAnchor constraintEqualToAnchor:control.leadingAnchor],
    [divider.trailingAnchor constraintEqualToAnchor:control.trailingAnchor],
    [divider.bottomAnchor constraintEqualToAnchor:control.bottomAnchor],
    [divider.heightAnchor constraintEqualToConstant:1],
  ]];

  control.isAccessibilityElement = YES;
  control.accessibilityTraits = UIAccessibilityTraitButton;
  control.accessibilityLabel = [NSString stringWithFormat:@"%@, %@ %@", row.yearText, row.title, row.roleText];
  return control;
}

#pragma mark - Rendering

- (void)render:(MDBScreenState<MDBPersonContent *> *)state {
  MDBPersonContent *content = state.content;
  if (content) {
    [self renderHeader:content];
    [self renderSections:content];
  }
  [self renderPhase:state];
}

- (void)renderHeader:(MDBPersonContent *)content {
  self.title = content.name;
  self.nameLabel.text = content.name;
  self.departmentLabel.text = content.departmentText;
  self.departmentLabel.hidden = content.departmentText.length == 0;
  [self.profileView sd_setImageWithURL:content.profileURL placeholderImage:[UIImage systemImageNamed:@"person.fill"]
                               options:SDWebImageRetryFailed];
  for (UIView *view in self.factsStack.arrangedSubviews) {
    [view removeFromSuperview];
  }
  for (MDBPersonFact *fact in content.facts) {
    UILabel *key = [MDBTheme labelWithSize:11 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption2
                                     color:UIColor.mdb_textSecondary];
    key.text = fact.title;
    UILabel *value = [MDBTheme labelWithSize:13 weight:UIFontWeightMedium textStyle:UIFontTextStyleFootnote
                                       color:UIColor.mdb_textPrimary];
    value.text = fact.value;
    value.numberOfLines = 2;
    UIStackView *pair = [[UIStackView alloc] initWithArrangedSubviews:@[ key, value ]];
    pair.axis = UILayoutConstraintAxisVertical;
    pair.spacing = 1;
    [self.factsStack addArrangedSubview:pair];
  }
}

- (void)renderSections:(MDBPersonContent *)content {
  self.biographyLabel.text = content.biography;
  self.biographySection.hidden = content.biography.length == 0;
  self.readMoreButton.hidden = content.biography.length < 220;

  self.knownForItems = content.knownFor;
  self.knownForSection.hidden = self.knownForItems.count == 0;
  [self.knownForView reloadData];

  for (UIView *view in self.filmographyRows.arrangedSubviews) {
    [view removeFromSuperview];
  }
  self.filmographyItems = content.filmography;
  [self.filmographyItems enumerateObjectsUsingBlock:^(MDBFilmographyRow *row, NSUInteger index, BOOL *stop) {
    [self.filmographyRows addArrangedSubview:[self filmographyRowViewForRow:row index:(NSInteger)index]];
  }];
  self.filmographySection.hidden = self.filmographyItems.count == 0;
}

- (void)renderPhase:(MDBScreenState *)state {
  if (state.isLoading) {
    [self.spinner startAnimating];
  } else {
    [self.spinner stopAnimating];
  }
  NSError *error = state.error;
  self.stateView.hidden = state.phase != MDBLoadStateFailed;
  if (state.phase == MDBLoadStateFailed && error) {
    [self.stateView configureWithError:error];
  }
  if (!self.hasFinishedFirstLoad && !state.isLoading) {
    self.hasFinishedFirstLoad = YES;
    [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Person"];
  }
}

#pragma mark - Actions

- (void)readMoreTapped {
  self.biographyExpanded = !self.biographyExpanded;
  self.biographyLabel.numberOfLines = self.biographyExpanded ? 0 : 4;
  UIButtonConfiguration *configuration = self.readMoreButton.configuration;
  configuration.title = self.biographyExpanded ? @"Show less" : @"Read more";
  self.readMoreButton.configuration = configuration;
}

- (void)filmographyTapped:(UIControl *)sender {
  NSArray<MDBFilmographyRow *> *rows = self.filmographyItems;
  if (sender.tag >= 0 && sender.tag < (NSInteger)rows.count) {
    [self.delegate personViewController:self didSelectMovie:rows[(NSUInteger)sender.tag].movie];
  }
}

#pragma mark - Known For

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return (NSInteger)self.knownForItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
  [cell configureWithModel:self.knownForItems[(NSUInteger)indexPath.item] style:MDBPosterCellStyleTitled];
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  [self.delegate personViewController:self didSelectMovie:self.knownForItems[(NSUInteger)indexPath.item]];
}

@end
