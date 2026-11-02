//
//  MDBMovieListViewController.m
//  MovieDB
//

#import "MDBMovieListViewController.h"
#import "MDBChipsRowCell.h"
#import "MDBLayoutFactory.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieListViewModel.h"
#import "MDBPosterCell.h"
#import "MDBStateView.h"
#import "MDBTheme.h"

static NSString *const MDBLoadingFooterKind = @"MDBLoadingFooterKind";

@interface MDBLoadingFooterView : UICollectionReusableView
@property (nonatomic, readonly) UIActivityIndicatorView *spinner;
@property (nonatomic, readonly) UILabel *label;
@end

@implementation MDBLoadingFooterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        _spinner.color = UIColor.mdb_accent;
        _label = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote color:UIColor.mdb_textSecondary];
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_spinner, _label]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.spacing = 8;
        [self addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [stack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        ]];
    }
    return self;
}

@end

typedef NS_ENUM(NSInteger, MDBMovieListSection) {
    MDBMovieListSectionSort = 0,
    MDBMovieListSectionGrid,
};

@interface MDBMovieListViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) MDBMovieListViewModel *viewModel;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) MDBStateView *stateView;
@end

@implementation MDBMovieListViewController

- (instancetype)initWithViewModel:(MDBMovieListViewModel *)viewModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = viewModel;
        self.title = viewModel.title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.mdb_background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;

    BOOL showsSort = self.viewModel.showsSortOptions;
    UICollectionViewCompositionalLayout *layout =
        [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger section, id<NSCollectionLayoutEnvironment> environment) {
            if (section == MDBMovieListSectionSort) {
                return [MDBLayoutFactory fullWidthSectionWithEstimatedHeight:showsSort ? 36 : 1];
            }
            NSCollectionLayoutSection *grid = [MDBLayoutFactory posterGridSectionWithEnvironment:environment hasHeader:NO];
            NSCollectionLayoutSize *footerSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                                heightDimension:[NSCollectionLayoutDimension absoluteDimension:56]];
            grid.boundarySupplementaryItems = @[[NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:footerSize
                                                                                                                       elementKind:MDBLoadingFooterKind
                                                                                                                         alignment:NSRectAlignmentBottom]];
            return grid;
        }];

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.mdb_background;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[MDBChipsRowCell class] forCellWithReuseIdentifier:MDBChipsRowCell.identifier];
    [self.collectionView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
    [self.collectionView registerClass:[MDBLoadingFooterView class]
            forSupplementaryViewOfKind:MDBLoadingFooterKind
                   withReuseIdentifier:@"footer"];
    [self.view addSubview:self.collectionView];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.color = UIColor.mdb_accent;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    self.stateView = [[MDBStateView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    self.stateView.onAction = ^{
        [weakSelf.viewModel loadFirstPage];
    };
    [self.view addSubview:self.stateView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.stateView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.stateView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.stateView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:showsSort ? 52 : 0],
        [self.stateView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
    ]];

    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self render];
    [self.viewModel loadFirstPage];
}

- (void)render {
    MDBMovieListViewModel *viewModel = self.viewModel;
    if (viewModel.state == MDBLoadStateLoading && viewModel.items.count == 0) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
    switch (viewModel.state) {
        case MDBLoadStateFailed: {
            self.stateView.hidden = NO;
            NSError *error = viewModel.error;
            if (error) {
                [self.stateView configureWithError:error];
            }
            break;
        }
        case MDBLoadStateEmpty:
            self.stateView.hidden = NO;
            [self.stateView configureWithSymbolName:@"film"
                                              title:@"No movies here"
                                            message:@"TMDB has nothing for this list right now."
                                        actionTitle:nil
                                   actionSymbolName:nil];
            break;
        default:
            self.stateView.hidden = YES;
            break;
    }
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == MDBMovieListSectionSort) {
        return self.viewModel.showsSortOptions ? 1 : 0;
    }
    return (NSInteger)self.viewModel.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MDBMovieListSectionSort) {
        MDBChipsRowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBChipsRowCell.identifier forIndexPath:indexPath];
        [cell configureWithTitles:self.viewModel.sortTitles selectedIndex:self.viewModel.sort];
        __weak typeof(self) weakSelf = self;
        cell.onSelectIndex = ^(NSInteger index) {
            [weakSelf.viewModel selectSortAtIndex:index];
        };
        return cell;
    }
    MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
    [cell configureWithModel:self.viewModel.items[(NSUInteger)indexPath.item] style:MDBPosterCellStyleTitled];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    MDBLoadingFooterView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                      withReuseIdentifier:@"footer"
                                                                             forIndexPath:indexPath];
    if (self.viewModel.isLoadingMore) {
        [footer.spinner startAnimating];
        footer.label.text = @"Loading more…";
    } else {
        [footer.spinner stopAnimating];
        footer.label.text = nil;
    }
    return footer;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MDBMovieListSectionGrid) {
        [self.viewModel loadMoreIfNeededForIndex:indexPath.item];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MDBMovieListSectionGrid) {
        [self.delegate movieListViewController:self didSelectMovie:self.viewModel.items[(NSUInteger)indexPath.item]];
    }
}

@end
