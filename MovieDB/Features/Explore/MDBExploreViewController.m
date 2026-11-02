//
//  MDBExploreViewController.m
//  MovieDB
//

#import "MDBExploreViewController.h"
#import "MDBChipsRowCell.h"
#import "MDBExploreViewModel.h"
#import "MDBGenre.h"
#import "MDBLayoutFactory.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieListCell.h"
#import "MDBPosterCell.h"
#import "MDBSectionHeaderView.h"
#import "MDBSignpost.h"
#import "MDBStateView.h"
#import "MDBTheme.h"

typedef NS_ENUM(NSInteger, MDBExploreBrowseSection) {
    MDBExploreBrowseSectionGenres = 0,
    MDBExploreBrowseSectionTrending,
};

@interface MDBExploreViewController () <UICollectionViewDataSource, UICollectionViewDelegate,
                                        UITableViewDataSource, UITableViewDelegate,
                                        UISearchResultsUpdating, UISearchBarDelegate>
@property (nonatomic, readonly) MDBExploreViewModel *viewModel;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) UICollectionView *browseView;
@property (nonatomic) UITableView *resultsView;
@property (nonatomic) UILabel *resultsHeaderLabel;
@property (nonatomic) UIActivityIndicatorView *spinner;
@property (nonatomic) MDBStateView *stateView;
@property (nonatomic) os_signpost_id_t loadSignpost;
@property (nonatomic) BOOL hasFinishedFirstLoad;
@end

@implementation MDBExploreViewController

- (instancetype)initWithViewModel:(MDBExploreViewModel *)viewModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = viewModel;
        self.title = @"Explore";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadSignpost = [MDBSignpost beginScreenLoad:@"Explore"];
    self.view.backgroundColor = UIColor.mdb_background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;

    [self setUpSearch];
    [self setUpBrowseView];
    [self setUpResultsView];
    [self setUpOverlays];

    __weak typeof(self) weakSelf = self;
    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self render];
    [self.viewModel loadIfNeeded];
}

- (void)focusSearch {
    [self loadViewIfNeeded];
    // Wait a run loop turn so the tab switch finishes before the keyboard comes up.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.searchController.searchBar becomeFirstResponder];
    });
}

#pragma mark - Setup

- (void)setUpSearch {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = @"Search movies by title";
    self.searchController.searchBar.searchTextField.textColor = UIColor.mdb_textPrimary;
    self.searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.searchController.searchBar.returnKeyType = UIReturnKeySearch;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
}

- (void)setUpBrowseView {
    UICollectionViewCompositionalLayout *layout =
        [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger section, id<NSCollectionLayoutEnvironment> environment) {
            if (section == MDBExploreBrowseSectionGenres) {
                return [MDBLayoutFactory fullWidthSectionWithEstimatedHeight:36];
            }
            return [MDBLayoutFactory posterGridSectionWithEnvironment:environment hasHeader:YES];
        }];

    self.browseView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.browseView.translatesAutoresizingMaskIntoConstraints = NO;
    self.browseView.backgroundColor = UIColor.mdb_background;
    self.browseView.dataSource = self;
    self.browseView.delegate = self;
    self.browseView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.browseView registerClass:[MDBChipsRowCell class] forCellWithReuseIdentifier:MDBChipsRowCell.identifier];
    [self.browseView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
    [self.browseView registerClass:[MDBSectionHeaderView class]
        forSupplementaryViewOfKind:MDBSectionHeaderKind
               withReuseIdentifier:MDBSectionHeaderView.identifier];
    [self.view addSubview:self.browseView];
    [self pinToEdges:self.browseView];
}

- (void)setUpResultsView {
    self.resultsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.resultsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultsView.backgroundColor = UIColor.mdb_background;
    self.resultsView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.resultsView.dataSource = self;
    self.resultsView.delegate = self;
    self.resultsView.rowHeight = UITableViewAutomaticDimension;
    self.resultsView.estimatedRowHeight = 125;
    self.resultsView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.resultsView.sectionHeaderTopPadding = 0;
    [self.resultsView registerClass:[MDBMovieListCell class] forCellReuseIdentifier:MDBMovieListCell.identifier];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    self.resultsHeaderLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleSubheadline color:UIColor.mdb_textSecondary];
    [header addSubview:self.resultsHeaderLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.resultsHeaderLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [self.resultsHeaderLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
        [self.resultsHeaderLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
    ]];
    self.resultsView.tableHeaderView = header;

    UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    footerSpinner.color = UIColor.mdb_accent;
    footerSpinner.frame = CGRectMake(0, 0, 320, 56);
    self.resultsView.tableFooterView = footerSpinner;

    [self.view addSubview:self.resultsView];
    [self pinToEdges:self.resultsView];
}

- (void)setUpOverlays {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.color = UIColor.mdb_accent;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    self.stateView = [[MDBStateView alloc] initWithFrame:CGRectZero];
    __weak typeof(self) weakSelf = self;
    self.stateView.onAction = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.viewModel.mode == MDBExploreModeSearch) {
            [strongSelf.viewModel retrySearch];
        } else {
            [strongSelf.viewModel reloadBrowse];
        }
    };
    [self.view addSubview:self.stateView];
    [self pinToEdges:self.stateView];
    [NSLayoutConstraint activateConstraints:@[
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
    ]];
}

- (void)pinToEdges:(UIView *)view {
    [NSLayoutConstraint activateConstraints:@[
        [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

#pragma mark - Rendering

- (void)render {
    MDBExploreViewModel *viewModel = self.viewModel;
    BOOL searching = viewModel.mode == MDBExploreModeSearch;
    self.browseView.hidden = searching;
    self.resultsView.hidden = !searching;
    self.stateView.hidden = YES;
    [self.spinner stopAnimating];

    if (searching) {
        switch (viewModel.searchState) {
            case MDBLoadStateIdle:
                break;
            case MDBLoadStateLoading:
                if (viewModel.results.count == 0) {
                    [self.spinner startAnimating];
                }
                break;
            case MDBLoadStateLoaded:
                break;
            case MDBLoadStateEmpty:
                self.stateView.hidden = NO;
                [self.stateView configureWithSymbolName:@"magnifyingglass"
                                                  title:@"No movies found"
                                                message:[NSString stringWithFormat:@"Nothing matched “%@”. Check the spelling or try a different title.", viewModel.query]
                                            actionTitle:nil
                                       actionSymbolName:nil];
                break;
            case MDBLoadStateFailed:
                self.stateView.hidden = NO;
                [self showError:viewModel.searchError];
                break;
        }
        self.resultsHeaderLabel.text = viewModel.searchState == MDBLoadStateLoaded ? [viewModel resultsSummary] : nil;
        UIActivityIndicatorView *footer = (UIActivityIndicatorView *)self.resultsView.tableFooterView;
        if (viewModel.isLoadingMore) {
            [footer startAnimating];
        } else {
            [footer stopAnimating];
        }
        [self.resultsView reloadData];
    } else {
        switch (viewModel.browseState) {
            case MDBLoadStateIdle:
            case MDBLoadStateLoading:
                if (viewModel.trendingItems.count == 0) {
                    [self.spinner startAnimating];
                }
                break;
            case MDBLoadStateFailed:
                self.stateView.hidden = viewModel.trendingItems.count > 0;
                [self showError:viewModel.browseError];
                break;
            default:
                break;
        }
        [self.browseView reloadData];
    }

    if (!self.hasFinishedFirstLoad && viewModel.browseState != MDBLoadStateLoading && viewModel.browseState != MDBLoadStateIdle) {
        self.hasFinishedFirstLoad = YES;
        [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Explore"];
    }
}

- (void)showError:(nullable NSError *)error {
    NSError *value = error;
    if (value) {
        [self.stateView configureWithError:value];
    }
}

#pragma mark - Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self.viewModel updateQuery:searchController.searchBar.text ?: @""];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self.viewModel submitQuery];
}

#pragma mark - Browse collection

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == MDBExploreBrowseSectionGenres) {
        return self.viewModel.genreShortcuts.count > 0 ? 1 : 0;
    }
    return (NSInteger)self.viewModel.trendingItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MDBExploreBrowseSectionGenres) {
        MDBChipsRowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBChipsRowCell.identifier forIndexPath:indexPath];
        NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithObject:@"All"];
        for (MDBGenre *genre in self.viewModel.genreShortcuts) {
            [titles addObject:genre.name];
        }
        [cell configureWithTitles:titles selectedIndex:0];
        __weak typeof(self) weakSelf = self;
        cell.onSelectIndex = ^(NSInteger index) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSArray<MDBGenre *> *genres = strongSelf.viewModel.genreShortcuts;
            if (strongSelf && index > 0 && index - 1 < (NSInteger)genres.count) {
                [strongSelf.delegate exploreViewController:strongSelf didSelectGenre:genres[(NSUInteger)index - 1]];
            }
        };
        return cell;
    }
    MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
    [cell configureWithModel:self.viewModel.trendingItems[(NSUInteger)indexPath.item] style:MDBPosterCellStyleTitled];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    MDBSectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                      withReuseIdentifier:MDBSectionHeaderView.identifier
                                                                             forIndexPath:indexPath];
    [header configureWithTitle:@"Trending this week" showsSeeAll:NO];
    return header;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MDBExploreBrowseSectionTrending) {
        [self.delegate exploreViewController:self didSelectMovie:self.viewModel.trendingItems[(NSUInteger)indexPath.item]];
    }
}

#pragma mark - Results table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.viewModel.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MDBMovieListCell *cell = [tableView dequeueReusableCellWithIdentifier:MDBMovieListCell.identifier forIndexPath:indexPath];
    [cell configureWithModel:self.viewModel.results[(NSUInteger)indexPath.row] showsFavorite:NO];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel loadMoreResultsIfNeededForIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchController.searchBar resignFirstResponder];
    [self.delegate exploreViewController:self didSelectMovie:self.viewModel.results[(NSUInteger)indexPath.row]];
}

@end
