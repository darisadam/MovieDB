//
//  MDBFavoritesViewController.m
//  MovieDB
//

#import "MDBFavoritesViewController.h"
#import "MDBFavoritesViewModel.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieListCell.h"
#import "MDBStateView.h"
#import "MDBTheme.h"

@interface MDBFavoritesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, readonly) MDBFavoritesViewModel *viewModel;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UILabel *summaryLabel;
@property (nonatomic) MDBStateView *emptyView;
@end

@implementation MDBFavoritesViewController

- (instancetype)initWithViewModel:(MDBFavoritesViewModel *)viewModel {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = viewModel;
        self.title = @"Favorites";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.mdb_background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.mdb_background;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 125;
    [self.tableView registerClass:[MDBMovieListCell class] forCellReuseIdentifier:MDBMovieListCell.identifier];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 36)];
    self.summaryLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1 color:[UIColor colorWithWhite:1 alpha:0.5]];
    [header addSubview:self.summaryLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.summaryLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:20],
        [self.summaryLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
    ]];
    self.tableView.tableHeaderView = header;
    [self.view addSubview:self.tableView];

    self.emptyView = [[MDBStateView alloc] initWithFrame:CGRectZero];
    [self.emptyView configureWithSymbolName:@"heart"
                                      title:@"No favorites yet"
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

    for (UIView *view in @[self.tableView, self.emptyView]) {
        [NSLayoutConstraint activateConstraints:@[
            [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        ]];
    }

    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self.viewModel reload];
}

- (void)render {
    self.summaryLabel.text = [self.viewModel summaryText];
    self.emptyView.hidden = self.viewModel.items.count > 0;
    self.tableView.hidden = self.viewModel.items.count == 0;
    [self.tableView reloadData];
}

- (void)removeRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel removeItemAtIndex:(NSUInteger)indexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    self.summaryLabel.text = [self.viewModel summaryText];
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.viewModel.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MDBMovieListCell *cell = [tableView dequeueReusableCellWithIdentifier:MDBMovieListCell.identifier forIndexPath:indexPath];
    MDBMovieCellModel *model = self.viewModel.items[(NSUInteger)indexPath.row];
    [cell configureWithModel:model showsFavorite:YES];

    NSInteger movieID = model.movieID;
    __weak typeof(self) weakSelf = self;
    cell.onFavoriteTapped = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // Look the row up again, it may have moved since this cell was configured.
        NSUInteger index = [strongSelf.viewModel.items indexOfObjectPassingTest:^BOOL(MDBMovieCellModel *item, NSUInteger idx, BOOL *stop) {
            return item.movieID == movieID;
        }];
        if (strongSelf && index != NSNotFound) {
            [strongSelf removeRowAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)index inSection:0]];
        }
    };
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.delegate favoritesViewController:self didSelectMovie:self.viewModel.items[(NSUInteger)indexPath.row]];
}

- (nullable UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                         title:@"Remove"
                                                                       handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [weakSelf removeRowAtIndexPath:indexPath];
        completionHandler(YES);
    }];
    remove.image = [UIImage systemImageNamed:@"trash"];
    remove.backgroundColor = UIColor.mdb_danger;
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

@end
