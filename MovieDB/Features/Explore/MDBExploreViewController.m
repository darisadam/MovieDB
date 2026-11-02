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
#import "MDBObservable.h"
#import "MDBPagedItems.h"
#import "MDBPosterCell.h"
#import "MDBScreenState.h"
#import "MDBSectionHeaderView.h"
#import "MDBSignpost.h"
#import "MDBStateView.h"
#import "MDBTheme.h"
#import "UIView+MDBLayout.h"

typedef NS_ENUM(NSInteger, MDBExploreBrowseSection) {
  MDBExploreBrowseSectionGenres = 0,
  MDBExploreBrowseSectionTrending,
};

@interface MDBExploreViewController () <UICollectionViewDataSource,
                                        UICollectionViewDelegate,
                                        UITableViewDataSource,
                                        UITableViewDelegate,
                                        UISearchResultsUpdating,
                                        UISearchBarDelegate>
@property (nonatomic, readonly) MDBExploreViewModel *viewModel;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic) MDBExploreMode mode;
@property (nonatomic, nullable) MDBScreenState<MDBExploreBrowseContent *> *browse;
@property (nonatomic, nullable) MDBScreenState<MDBPagedItems *> *search;
@property (nonatomic, copy) NSArray<MDBMovieCellModel *> *trendingItems;
@property (nonatomic, copy) NSArray<MDBGenre *> *genreShortcuts;
@property (nonatomic, copy) NSArray<MDBMovieCellModel *> *results;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic) UICollectionView *browseView;
@property (nonatomic) UITableView *resultsView;
@property (nonatomic) UILabel *resultsHeaderLabel;
@property (nonatomic) UIActivityIndicatorView *footerSpinner;
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
    _bag = [[MDBDisposeBag alloc] init];
    _trendingItems = @[];
    _genreShortcuts = @[];
    _results = @[];
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
  [self bindViewModel];
  [self.viewModel loadIfNeeded];
}

- (void)bindViewModel {
  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[self.viewModel.mode subscribe:^(NSNumber *mode) {
              __strong typeof(weakSelf) strongSelf = weakSelf;
              strongSelf.mode = (MDBExploreMode)mode.integerValue;
              [strongSelf render];
            }]];
  [self.bag addDisposable:[self.viewModel.browseState subscribe:^(MDBScreenState<MDBExploreBrowseContent *> *state) {
              __strong typeof(weakSelf) strongSelf = weakSelf;
              strongSelf.browse = state;
              if (state.content) {
                strongSelf.trendingItems = state.content.trendingItems;
                strongSelf.genreShortcuts = state.content.genreShortcuts;
              }
              [strongSelf render];
            }]];
  [self.bag addDisposable:[self.viewModel.searchState subscribe:^(MDBScreenState<MDBPagedItems *> *state) {
              __strong typeof(weakSelf) strongSelf = weakSelf;
              strongSelf.search = state;
              strongSelf.results = state.content.items ?: @[];
              [strongSelf render];
            }]];
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
  UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc]
      initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger section, id<NSCollectionLayoutEnvironment> environment) {
        if (section == MDBExploreBrowseSectionGenres) {
          return [MDBLayoutFactory fullWidthSectionWithEstimatedHeight:36];
        }
        return [MDBLayoutFactory posterGridSectionWithEnvironment:environment hasHeader:YES];
      }];

  self.browseView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.browseView.backgroundColor = UIColor.mdb_background;
  self.browseView.dataSource = self;
  self.browseView.delegate = self;
  self.browseView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  [self.browseView registerClass:[MDBChipsRowCell class] forCellWithReuseIdentifier:MDBChipsRowCell.identifier];
  [self.browseView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
  [self.browseView registerClass:[MDBSectionHeaderView class] forSupplementaryViewOfKind:MDBSectionHeaderKind
             withReuseIdentifier:MDBSectionHeaderView.identifier];
  [self.view addSubview:self.browseView];
  [self.browseView mdb_pinToEdgesOfView:self.view];
}

- (void)setUpResultsView {
  self.resultsView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
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
  self.resultsHeaderLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleSubheadline
                                              color:UIColor.mdb_textSecondary];
  [header addSubview:self.resultsHeaderLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.resultsHeaderLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
    [self.resultsHeaderLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-20],
    [self.resultsHeaderLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
  ]];
  self.resultsView.tableHeaderView = header;

  self.footerSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
  self.footerSpinner.color = UIColor.mdb_accent;
  self.footerSpinner.frame = CGRectMake(0, 0, 320, 56);
  self.resultsView.tableFooterView = self.footerSpinner;

  [self.view addSubview:self.resultsView];
  [self.resultsView mdb_pinToEdgesOfView:self.view];
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
    if (strongSelf.mode == MDBExploreModeSearch) {
      [strongSelf.viewModel retrySearch];
    } else {
      [strongSelf.viewModel reloadBrowse];
    }
  };
  [self.view addSubview:self.stateView];
  [self.stateView mdb_pinToEdgesOfView:self.view];
  [NSLayoutConstraint activateConstraints:@[
    [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.spinner.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
  ]];
}

#pragma mark - Rendering

- (void)render {
  if (!self.isViewLoaded) {
    return;
  }
  BOOL searching = self.mode == MDBExploreModeSearch;
  self.browseView.hidden = searching;
  self.resultsView.hidden = !searching;
  self.stateView.hidden = YES;
  [self.spinner stopAnimating];
  if (searching) {
    [self renderSearch:self.search];
  } else {
    [self renderBrowse:self.browse];
  }
}

- (void)renderSearch:(nullable MDBScreenState<MDBPagedItems *> *)state {
  MDBPagedItems *items = state.content;
  switch (state.phase) {
    case MDBLoadStateLoading:
      if (self.results.count == 0) {
        [self.spinner startAnimating];
      }
      break;
    case MDBLoadStateEmpty: {
      NSString *query = self.viewModel.query.value ?: @"";
      self.stateView.hidden = NO;
      [self.stateView
          configureWithSymbolName:@"magnifyingglass"
                            title:@"No movies found"
                          message:[NSString
                                      stringWithFormat:@"Nothing matched “%@”. Check the spelling or try a different title.",
                                                       query]
                      actionTitle:nil
                 actionSymbolName:nil];
      break;
    }
    case MDBLoadStateFailed: [self showError:state.error]; break;
    default: break;
  }
  self.resultsHeaderLabel.text = items ? [self.viewModel resultsSummaryForItems:items] : nil;
  if (items.isLoadingMore) {
    [self.footerSpinner startAnimating];
  } else {
    [self.footerSpinner stopAnimating];
  }
  [self.resultsView reloadData];
}

- (void)renderBrowse:(nullable MDBScreenState<MDBExploreBrowseContent *> *)state {
  BOOL hasItems = self.trendingItems.count > 0;
  if ((state.isLoading || state.phase == MDBLoadStateIdle) && !hasItems) {
    [self.spinner startAnimating];
  } else if (state.phase == MDBLoadStateFailed && !hasItems) {
    [self showError:state.error];
  }
  if (state && !state.isLoading && state.phase != MDBLoadStateIdle && !self.hasFinishedFirstLoad) {
    self.hasFinishedFirstLoad = YES;
    [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Explore"];
  }
  [self.browseView reloadData];
}

- (void)showError:(nullable NSError *)error {
  NSError *value = error;
  if (value) {
    self.stateView.hidden = NO;
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
    return self.genreShortcuts.count > 0 ? 1 : 0;
  }
  return (NSInteger)self.trendingItems.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == MDBExploreBrowseSectionGenres) {
    MDBChipsRowCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBChipsRowCell.identifier
                                                                      forIndexPath:indexPath];
    NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithObject:@"All"];
    for (MDBGenre *genre in self.genreShortcuts) {
      [titles addObject:genre.name];
    }
    [cell configureWithTitles:titles selectedIndex:0];
    __weak typeof(self) weakSelf = self;
    cell.onSelectIndex = ^(NSInteger index) {
      [weakSelf selectGenreShortcutAtIndex:index - 1];
    };
    return cell;
  }
  MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
  [cell configureWithModel:self.trendingItems[(NSUInteger)indexPath.item] style:MDBPosterCellStyleTitled];
  return cell;
}

- (void)selectGenreShortcutAtIndex:(NSInteger)index {
  if (index >= 0 && index < (NSInteger)self.genreShortcuts.count) {
    [self.delegate exploreViewController:self didSelectGenre:self.genreShortcuts[(NSUInteger)index]];
  }
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
    [self.delegate exploreViewController:self didSelectMovie:self.trendingItems[(NSUInteger)indexPath.item]];
  }
}

#pragma mark - Results table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MDBMovieListCell *cell = [tableView dequeueReusableCellWithIdentifier:MDBMovieListCell.identifier forIndexPath:indexPath];
  [cell configureWithModel:self.results[(NSUInteger)indexPath.row] showsFavorite:NO];
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.viewModel loadMoreResultsIfNeededForIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [self.searchController.searchBar resignFirstResponder];
  [self.delegate exploreViewController:self didSelectMovie:self.results[(NSUInteger)indexPath.row]];
}

@end
