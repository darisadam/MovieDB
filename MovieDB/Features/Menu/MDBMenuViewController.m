//
//  MDBMenuViewController.m
//  MovieDB
//

#import "MDBMenuViewController.h"
#import "MDBAPIError.h"
#import "MDBButtonFactory.h"
#import "MDBGenre.h"
#import "MDBListRowButton.h"
#import "MDBMenuViewModel.h"
#import "MDBObservable.h"
#import "MDBPreferences.h"
#import "MDBScreenState.h"
#import "MDBTheme.h"
#import "MDBWrapView.h"
#import "UIView+MDBLayout.h"

@interface MDBMenuViewController ()
@property (nonatomic, readonly) MDBMenuViewModel *viewModel;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic, copy) NSArray<MDBGenre *> *genres;
@property (nonatomic) NSUInteger favoritesCount;
@property (nonatomic) MDBWrapView *genreWrap;
@property (nonatomic) UIStackView *genreStatus;
@property (nonatomic) UILabel *genreStatusLabel;
@property (nonatomic) UIButton *genreRetryButton;
@property (nonatomic) MDBListRowButton *regionRow;
@property (nonatomic) MDBListRowButton *languageRow;
@property (nonatomic) MDBListRowButton *clearRow;
@end

@implementation MDBMenuViewController

- (instancetype)initWithViewModel:(MDBMenuViewModel *)viewModel {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    _bag = [[MDBDisposeBag alloc] init];
    _genres = @[];
    self.title = @"Menu";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.mdb_background;
  self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
  self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
  [self buildLayout];
  [self bindViewModel];
  [self.viewModel loadIfNeeded];
}

#pragma mark - Building

- (void)buildLayout {
  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.alwaysBounceVertical = YES;
  [self.view addSubview:scrollView];
  [scrollView mdb_pinToEdgesOfView:self.view];

  UIStackView *content = [[UIStackView alloc] init];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.axis = UILayoutConstraintAxisVertical;
  content.spacing = 14;
  [scrollView addSubview:content];
  [NSLayoutConstraint activateConstraints:@[
    [content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20],
    [content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20],
    [content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:12],
    [content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-32],
    [content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40],
  ]];

  [content addArrangedSubview:[MDBTheme sectionTitleLabel:@"Browse by Genre"]];
  self.genreWrap = [[MDBWrapView alloc] initWithFrame:CGRectZero];
  [content addArrangedSubview:self.genreWrap];
  [content addArrangedSubview:[self makeGenreStatus]];
  [content setCustomSpacing:32 afterView:self.genreStatus];
  [content addArrangedSubview:[MDBTheme sectionTitleLabel:@"Preferences"]];
  [content addArrangedSubview:[self makePreferenceRows]];
}

- (UIView *)makeGenreStatus {
  self.genreStatusLabel = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote
                                            color:UIColor.mdb_textSecondary];
  self.genreStatusLabel.numberOfLines = 0;
  self.genreRetryButton = [MDBButtonFactory buttonWithStyle:MDBButtonStyleSecondary title:@"Try Again"
                                                 symbolName:@"arrow.clockwise"];
  [self.genreRetryButton addTarget:self action:@selector(retryGenresTapped) forControlEvents:UIControlEventTouchUpInside];
  self.genreStatus = [[UIStackView alloc] initWithArrangedSubviews:@[ self.genreStatusLabel, self.genreRetryButton ]];
  self.genreStatus.axis = UILayoutConstraintAxisVertical;
  self.genreStatus.alignment = UIStackViewAlignmentLeading;
  self.genreStatus.spacing = 10;
  return self.genreStatus;
}

- (UIView *)makePreferenceRows {
  self.regionRow = [MDBListRowButton rowWithSymbolName:@"globe" title:@"Region"];
  self.regionRow.showsMenuAsPrimaryAction = YES;
  self.languageRow = [MDBListRowButton rowWithSymbolName:@"character.bubble" title:@"Language"];
  self.languageRow.showsMenuAsPrimaryAction = YES;
  self.clearRow = [MDBListRowButton rowWithSymbolName:@"trash" title:@"Clear Favorites"];
  self.clearRow.destructive = YES;
  self.clearRow.showsChevron = NO;
  [self.clearRow addTarget:self action:@selector(clearFavoritesTapped) forControlEvents:UIControlEventTouchUpInside];
  MDBListRowButton *aboutRow = [MDBListRowButton rowWithSymbolName:@"info.circle" title:@"About MovieDB"];
  [aboutRow addTarget:self action:@selector(aboutTapped) forControlEvents:UIControlEventTouchUpInside];

  UIStackView *rows =
      [[UIStackView alloc] initWithArrangedSubviews:@[ self.regionRow, self.languageRow, self.clearRow, aboutRow ]];
  rows.axis = UILayoutConstraintAxisVertical;
  return rows;
}

- (UIMenu *)menuWithOptions:(NSArray<MDBPreferenceOption *> *)options
                   selected:(MDBPreferenceOption *)selected
                    handler:(void (^)(NSString *code))handler {
  NSMutableArray<UIAction *> *actions = [NSMutableArray arrayWithCapacity:options.count];
  for (MDBPreferenceOption *option in options) {
    NSString *code = option.code;
    UIAction *action = [UIAction actionWithTitle:option.title image:nil identifier:nil handler:^(__kindof UIAction *a) {
      handler(code);
    }];
    action.state = [option isEqual:selected] ? UIMenuElementStateOn : UIMenuElementStateOff;
    [actions addObject:action];
  }
  return [UIMenu menuWithTitle:@"" children:actions];
}

#pragma mark - Binding

- (void)bindViewModel {
  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[self.viewModel.genresState subscribe:^(MDBScreenState<NSArray<MDBGenre *> *> *state) {
              [weakSelf renderGenres:state];
            }]];
  [self.bag addDisposable:[self.viewModel.preferences subscribe:^(MDBPreferenceSnapshot *snapshot) {
              [weakSelf renderPreferences:snapshot];
            }]];
  [self.bag addDisposable:[self.viewModel.favoritesCount subscribe:^(NSNumber *count) {
              [weakSelf renderFavoritesCount:count.unsignedIntegerValue];
            }]];
}

#pragma mark - Rendering

- (void)renderGenres:(MDBScreenState<NSArray<MDBGenre *> *> *)state {
  NSArray<MDBGenre *> *genres = state.content ?: @[];
  if (![genres isEqualToArray:self.genres]) {
    self.genres = genres;
    NSMutableArray<UIView *> *chips = [NSMutableArray arrayWithCapacity:genres.count];
    [genres enumerateObjectsUsingBlock:^(MDBGenre *genre, NSUInteger index, BOOL *stop) {
      UIButton *chip = [MDBButtonFactory chipWithTitle:genre.name];
      chip.tag = (NSInteger)index;
      [chip addTarget:self action:@selector(genreTapped:) forControlEvents:UIControlEventTouchUpInside];
      [chips addObject:chip];
    }];
    [self.genreWrap setItemViews:chips];
  }

  NSError *error = state.error;
  self.genreStatus.hidden = genres.count > 0 && state.phase != MDBLoadStateFailed;
  self.genreRetryButton.hidden = state.phase != MDBLoadStateFailed || error.mdb_isMissingToken;
  if (state.phase == MDBLoadStateFailed) {
    self.genreStatusLabel.text = error ? error.mdb_userFacingMessage : @"Couldn't load genres.";
  } else {
    self.genreStatusLabel.text = @"Loading genres…";
  }
}

- (void)renderPreferences:(MDBPreferenceSnapshot *)snapshot {
  __weak typeof(self) weakSelf = self;
  self.regionRow.valueText = snapshot.region.title;
  self.regionRow.menu = [self menuWithOptions:self.viewModel.regionOptions selected:snapshot.region handler:^(NSString *code) {
    [weakSelf.viewModel selectRegionCode:code];
  }];
  self.languageRow.valueText = snapshot.language.title;
  self.languageRow.menu = [self menuWithOptions:self.viewModel.languageOptions selected:snapshot.language
                                        handler:^(NSString *code) {
                                          [weakSelf.viewModel selectLanguageCode:code];
                                        }];
}

- (void)renderFavoritesCount:(NSUInteger)count {
  self.favoritesCount = count;
  self.clearRow.valueText = count > 0 ? [NSString stringWithFormat:@"%lu saved", (unsigned long)count] : @"None saved";
  self.clearRow.enabled = count > 0;
  self.clearRow.alpha = count > 0 ? 1 : 0.5;
}

#pragma mark - Actions

- (void)genreTapped:(UIButton *)sender {
  if (sender.tag >= 0 && sender.tag < (NSInteger)self.genres.count) {
    [self.delegate menuViewController:self didSelectGenre:self.genres[(NSUInteger)sender.tag]];
  }
}

- (void)retryGenresTapped {
  [self.viewModel reloadGenres];
}

- (void)aboutTapped {
  [self.delegate menuViewControllerDidSelectAbout:self];
}

- (void)clearFavoritesTapped {
  NSUInteger count = self.favoritesCount;
  NSString *message = [NSString stringWithFormat:@"This removes %lu saved %@ from this device. You can't undo it.",
                                                 (unsigned long)count, count == 1 ? @"movie" : @"movies"];
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear favorites?" message:message
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  __weak typeof(self) weakSelf = self;
  [alert addAction:[UIAlertAction actionWithTitle:@"Clear All" style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                            [weakSelf.viewModel clearFavorites];
                                          }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  alert.popoverPresentationController.sourceView = self.clearRow;
  alert.popoverPresentationController.sourceRect = self.clearRow.bounds;
  [self presentViewController:alert animated:YES completion:nil];
}

@end
