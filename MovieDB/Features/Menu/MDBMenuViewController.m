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
#import "MDBPreferences.h"
#import "MDBSkeletonView.h"
#import "MDBTheme.h"
#import "MDBWrapView.h"

@interface MDBMenuViewController ()
@property (nonatomic, readonly) MDBMenuViewModel *viewModel;
@property (nonatomic) MDBWrapView *genreWrap;
@property (nonatomic) UIStackView *genreStatus;
@property (nonatomic) UILabel *genreStatusLabel;
@property (nonatomic) UIButton *genreRetryButton;
@property (nonatomic) MDBListRowButton *regionRow;
@property (nonatomic) MDBListRowButton *languageRow;
@property (nonatomic) MDBListRowButton *clearRow;
@property (nonatomic, copy) NSArray<MDBGenre *> *renderedGenres;
@end

@implementation MDBMenuViewController

- (instancetype)initWithViewModel:(MDBMenuViewModel *)viewModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = viewModel;
        _renderedGenres = @[];
        self.title = @"Menu";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.mdb_background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];

    UIStackView *content = [[UIStackView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 14;
    [scrollView addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20],
        [content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:12],
        [content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-32],
        [content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40],
    ]];

    [content addArrangedSubview:[self sectionTitle:@"Browse by Genre"]];
    self.genreWrap = [[MDBWrapView alloc] initWithFrame:CGRectZero];
    [content addArrangedSubview:self.genreWrap];
    [content addArrangedSubview:[self makeGenreStatus]];
    [content setCustomSpacing:32 afterView:self.genreStatus];

    [content addArrangedSubview:[self sectionTitle:@"Preferences"]];
    UIStackView *rows = [[UIStackView alloc] init];
    rows.axis = UILayoutConstraintAxisVertical;
    [content addArrangedSubview:rows];

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

    for (UIView *row in @[self.regionRow, self.languageRow, self.clearRow, aboutRow]) {
        [rows addArrangedSubview:row];
    }

    __weak typeof(self) weakSelf = self;
    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self render];
    [self.viewModel loadIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self render];
}

#pragma mark - Building

- (UILabel *)sectionTitle:(NSString *)title {
    UILabel *label = [MDBTheme labelWithSize:17 weight:UIFontWeightBold textStyle:UIFontTextStyleHeadline color:UIColor.mdb_textPrimary];
    label.text = title;
    label.accessibilityTraits = UIAccessibilityTraitHeader;
    return label;
}

- (UIView *)makeGenreStatus {
    self.genreStatusLabel = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote color:UIColor.mdb_textSecondary];
    self.genreStatusLabel.numberOfLines = 0;
    self.genreRetryButton = [MDBButtonFactory buttonWithStyle:MDBButtonStyleSecondary title:@"Try Again" symbolName:@"arrow.clockwise"];
    [self.genreRetryButton addTarget:self action:@selector(retryGenresTapped) forControlEvents:UIControlEventTouchUpInside];
    self.genreStatus = [[UIStackView alloc] initWithArrangedSubviews:@[self.genreStatusLabel, self.genreRetryButton]];
    self.genreStatus.axis = UILayoutConstraintAxisVertical;
    self.genreStatus.alignment = UIStackViewAlignmentLeading;
    self.genreStatus.spacing = 10;
    return self.genreStatus;
}

- (UIMenu *)menuWithOptions:(NSArray<MDBPreferenceOption *> *)options
                selectedCode:(NSString *)selectedCode
                     handler:(void (^)(NSString *code))handler {
    NSMutableArray<UIAction *> *actions = [NSMutableArray arrayWithCapacity:options.count];
    for (MDBPreferenceOption *option in options) {
        NSString *code = option.code;
        UIAction *action = [UIAction actionWithTitle:option.title image:nil identifier:nil handler:^(__kindof UIAction *a) {
            handler(code);
        }];
        action.state = [code isEqualToString:selectedCode] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:action];
    }
    return [UIMenu menuWithTitle:@"" children:actions];
}

#pragma mark - Rendering

- (void)render {
    MDBMenuViewModel *viewModel = self.viewModel;

    if (![viewModel.genres isEqualToArray:self.renderedGenres]) {
        self.renderedGenres = viewModel.genres;
        NSMutableArray<UIView *> *chips = [NSMutableArray arrayWithCapacity:viewModel.genres.count];
        [viewModel.genres enumerateObjectsUsingBlock:^(MDBGenre *genre, NSUInteger index, BOOL *stop) {
            UIButton *chip = [MDBButtonFactory chipWithTitle:genre.name];
            chip.tag = (NSInteger)index;
            [chip addTarget:self action:@selector(genreTapped:) forControlEvents:UIControlEventTouchUpInside];
            [chips addObject:chip];
        }];
        [self.genreWrap setItemViews:chips];
    }

    switch (viewModel.genresState) {
        case MDBLoadStateLoading:
        case MDBLoadStateIdle:
            self.genreStatus.hidden = viewModel.genres.count > 0;
            self.genreStatusLabel.text = @"Loading genres…";
            self.genreRetryButton.hidden = YES;
            break;
        case MDBLoadStateFailed:
            self.genreStatus.hidden = NO;
            self.genreStatusLabel.text = viewModel.genresError.mdb_userFacingMessage ?: @"Couldn't load genres.";
            self.genreRetryButton.hidden = viewModel.genresError.mdb_isMissingToken;
            break;
        default:
            self.genreStatus.hidden = YES;
            break;
    }

    __weak typeof(self) weakSelf = self;
    self.regionRow.valueText = viewModel.regionTitle;
    self.regionRow.menu = [self menuWithOptions:viewModel.regionOptions selectedCode:viewModel.regionCode handler:^(NSString *code) {
        [weakSelf.viewModel selectRegionCode:code];
    }];
    self.languageRow.valueText = viewModel.languageTitle;
    self.languageRow.menu = [self menuWithOptions:viewModel.languageOptions selectedCode:viewModel.languageCode handler:^(NSString *code) {
        [weakSelf.viewModel selectLanguageCode:code];
    }];
    NSUInteger count = viewModel.favoritesCount;
    self.clearRow.valueText = count > 0 ? [NSString stringWithFormat:@"%lu saved", (unsigned long)count] : @"None saved";
    self.clearRow.enabled = count > 0;
    self.clearRow.alpha = count > 0 ? 1 : 0.5;
}

#pragma mark - Actions

- (void)genreTapped:(UIButton *)sender {
    NSArray<MDBGenre *> *genres = self.viewModel.genres;
    if (sender.tag >= 0 && sender.tag < (NSInteger)genres.count) {
        [self.delegate menuViewController:self didSelectGenre:genres[(NSUInteger)sender.tag]];
    }
}

- (void)retryGenresTapped {
    [self.viewModel reloadGenres];
}

- (void)aboutTapped {
    [self.delegate menuViewControllerDidSelectAbout:self];
}

- (void)clearFavoritesTapped {
    NSUInteger count = self.viewModel.favoritesCount;
    NSString *message = [NSString stringWithFormat:@"This removes %lu saved %@ from this device. You can't undo it.",
                         (unsigned long)count, count == 1 ? @"movie" : @"movies"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear favorites?"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear All" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf.viewModel clearFavorites];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    alert.popoverPresentationController.sourceView = self.clearRow;
    alert.popoverPresentationController.sourceRect = self.clearRow.bounds;
    [self presentViewController:alert animated:YES completion:nil];
}

@end
