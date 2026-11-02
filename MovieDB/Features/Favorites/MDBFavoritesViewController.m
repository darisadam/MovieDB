//
//  MDBFavoritesViewController.m
//  MovieDB
//

#import "MDBFavoritesViewController.h"
#import "MDBFavoritesViewModel.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieListCell.h"
#import "MDBObservable.h"
#import "MDBScreenState.h"
#import "MDBStateView.h"
#import "MDBTheme.h"
#import "UIView+MDBLayout.h"

@interface MDBFavoritesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly) MDBFavoritesViewModel *viewModel;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic, copy) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UILabel *summaryLabel;
@property (nonatomic) MDBStateView *emptyView;
@end

@implementation MDBFavoritesViewController

- (instancetype)initWithViewModel:(MDBFavoritesViewModel *)viewModel {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    _bag = [[MDBDisposeBag alloc] init];
    _items = @[];
    self.title = @"Favorites";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.mdb_background;
  self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
  self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
  [self setUpTableView];
  [self setUpEmptyView];

  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[self.viewModel.state subscribe:^(MDBScreenState<NSArray<MDBMovieCellModel *> *> *state) {
              [weakSelf render:state];
            }]];
}

#pragma mark - Setup

- (void)setUpTableView {
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.backgroundColor = UIColor.mdb_background;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.rowHeight = UITableViewAutomaticDimension;
  self.tableView.estimatedRowHeight = 125;
  [self.tableView registerClass:[MDBMovieListCell class] forCellReuseIdentifier:MDBMovieListCell.identifier];

  UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
  self.summaryLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                        color:[UIColor colorWithWhite:1 alpha:0.5]];
  [header addSubview:self.summaryLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.summaryLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
    [self.summaryLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
  ]];
  self.tableView.tableHeaderView = header;
  [self.view addSubview:self.tableView];
  [self.tableView mdb_pinToEdgesOfView:self.view];
}

- (void)setUpEmptyView {
  self.emptyView = [[MDBStateView alloc] initWithFrame:CGRectZero];
  [self.emptyView configureWithSymbolName:@"heart" title:@"No favorites yet"
                                  message:@"Tap “Add to Favorite” on any movie and it will be saved on this device."
                              actionTitle:@"Explore Movies"
                         actionSymbolName:@"magnifyingglass"];
  __weak typeof(self) weakSelf = self;
  self.emptyView.onAction = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf.delegate favoritesViewControllerDidRequestExplore:strongSelf];
    }
  };
  [self.view addSubview:self.emptyView];
  [self.emptyView mdb_pinToEdgesOfView:self.view];
}

#pragma mark - Rendering

- (void)render:(MDBScreenState<NSArray<MDBMovieCellModel *> *> *)state {
  self.items = state.content ?: @[];
  [self renderChrome];
  [self.tableView reloadData];
}

- (void)renderChrome {
  self.summaryLabel.text = [MDBFavoritesViewModel summaryForCount:self.items.count];
  self.emptyView.hidden = self.items.count > 0;
  self.tableView.hidden = self.items.count == 0;
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath {
  NSUInteger index = (NSUInteger)indexPath.row;
  if (index >= self.items.count) {
    return;
  }
  NSInteger movieID = self.items[index].movieID;
  // Update the table right away so the row animation lines up, the store follows in the background.
  NSMutableArray<MDBMovieCellModel *> *items = [self.items mutableCopy];
  [items removeObjectAtIndex:index];
  self.items = items;
  [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
  [self renderChrome];
  [self.viewModel removeMovieWithID:movieID];
  [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MDBMovieListCell *cell = [tableView dequeueReusableCellWithIdentifier:MDBMovieListCell.identifier forIndexPath:indexPath];
  MDBMovieCellModel *model = self.items[(NSUInteger)indexPath.row];
  [cell configureWithModel:model showsFavorite:YES];

  NSInteger movieID = model.movieID;
  __weak typeof(self) weakSelf = self;
  cell.onFavoriteTapped = ^{
    [weakSelf removeMovieWithID:movieID];
  };
  return cell;
}

/// Looks the row up again, it may have moved since the cell was configured.
- (void)removeMovieWithID:(NSInteger)movieID {
  NSUInteger index = [self.items indexOfObjectPassingTest:^BOOL(MDBMovieCellModel *item, NSUInteger idx, BOOL *stop) {
    return item.movieID == movieID;
  }];
  if (index != NSNotFound) {
    [self removeRowAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)index inSection:0]];
  }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [self.delegate favoritesViewController:self didSelectMovie:self.items[(NSUInteger)indexPath.row]];
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger movieID = self.items[(NSUInteger)indexPath.row].movieID;
  __weak typeof(self) weakSelf = self;
  UIContextualAction *remove = [UIContextualAction
      contextualActionWithStyle:UIContextualActionStyleDestructive
                          title:@"Remove"
                        handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
                          [weakSelf removeMovieWithID:movieID];
                          completionHandler(YES);
                        }];
  remove.image = [UIImage systemImageNamed:@"trash"];
  remove.backgroundColor = UIColor.mdb_danger;
  return [UISwipeActionsConfiguration configurationWithActions:@[ remove ]];
}

@end
