//
//  MDBDebugMenuViewController.m
//  MovieDB
//

#import "MDBDebugMenuViewController.h"

#if DEBUG

#import <SDWebImage/SDWebImage.h>
#import "MDBAPIClient.h"
#import "MDBAppDependencies.h"
#import "MDBDebugInspector.h"
#import "MDBLog.h"
#import "MDBMetricsSubscriber.h"
#import "MDBNetworkActivityLog.h"
#import "MDBTheme.h"
#if __has_include(<FLEX/FLEX.h>)
#import <FLEX/FLEX.h>
#define MDB_HAS_FLEX 1
#else
#define MDB_HAS_FLEX 0
#endif

#pragma mark - Text viewer

@interface MDBDebugTextViewController : UIViewController
@property (nonatomic, copy) NSString *text;
@end

@implementation MDBDebugTextViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.mdb_background;
  UITextView *textView = [[UITextView alloc] init];
  textView.translatesAutoresizingMaskIntoConstraints = NO;
  textView.editable = NO;
  textView.backgroundColor = UIColor.mdb_background;
  textView.textColor = UIColor.mdb_textPrimary;
  textView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
  textView.text = self.text;
  textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
  [self.view addSubview:textView];
  [NSLayoutConstraint activateConstraints:@[
    [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                         target:self
                                                                                         action:@selector(shareTapped:)];
}

- (void)shareTapped:(UIBarButtonItem *)sender {
  UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[ self.text ?: @"" ]
                                                                         applicationActivities:nil];
  activity.popoverPresentationController.barButtonItem = sender;
  [self presentViewController:activity animated:YES completion:nil];
}

@end

#pragma mark - Menu

@interface MDBDebugRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic, copy, nullable) void (^action)(void);
@property (nonatomic) BOOL destructive;
@end

@implementation MDBDebugRow
@end

@interface MDBDebugMenuViewController ()
@property (nonatomic, readonly) MDBAppDependencies *dependencies;
@property (nonatomic, copy, readonly) NSString *coordinatorTree;
@property (nonatomic, copy) NSArray<NSString *> *sectionTitles;
@property (nonatomic, copy) NSArray<NSArray<MDBDebugRow *> *> *sections;
@end

@implementation MDBDebugMenuViewController

- (instancetype)initWithDependencies:(MDBAppDependencies *)dependencies coordinatorTree:(NSString *)coordinatorTree {
  self = [super initWithStyle:UITableViewStyleInsetGrouped];
  if (self) {
    _dependencies = dependencies;
    _coordinatorTree = [coordinatorTree copy];
    _sectionTitles = @[];
    _sections = @[];
    self.title = @"Debug";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.tableView.backgroundColor = UIColor.mdb_background;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Row"];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(doneTapped)];
  [self rebuild];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self rebuild];
}

- (MDBDebugRow *)rowWithTitle:(NSString *)title detail:(nullable NSString *)detail action:(nullable void (^)(void))action {
  MDBDebugRow *row = [[MDBDebugRow alloc] init];
  row.title = title;
  row.detail = detail;
  row.action = action;
  return row;
}

- (void)rebuild {
  __weak typeof(self) weakSelf = self;
  MDBAppDependencies *deps = self.dependencies;
  NSDictionary *info = [NSBundle mainBundle].infoDictionary;

  NSArray<MDBDebugRow *> *status = @[
    [self rowWithTitle:@"Version"
                detail:[NSString stringWithFormat:@"%@ (%@)", info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]]
                action:nil],
    [self rowWithTitle:@"Configuration" detail:@"View" action:^{
      [weakSelf showText:[MDBDebugInspector configuration] title:@"Configuration"];
    }],
    [self rowWithTitle:@"Coordinator tree" detail:@"View" action:^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      [strongSelf showText:strongSelf.coordinatorTree ?: @"" title:@"Coordinators"];
    }],
  ];

  BOOL offline = deps.apiClient.simulatesOffline;
  NSUInteger requestCount = [deps.networkLog recentEntries].count;
  NSArray<MDBDebugRow *> *network = @[
    [self rowWithTitle:@"Simulate offline" detail:offline ? @"On" : @"Off" action:^{
      deps.apiClient.simulatesOffline = !deps.apiClient.simulatesOffline;
      MDBLogInfo(MDBLogCategoryApp, @"Offline mode %@ from the debug menu", deps.apiClient.simulatesOffline ? @"on" : @"off");
      [weakSelf rebuild];
    }],
    [self rowWithTitle:@"Recent requests" detail:[NSString stringWithFormat:@"%lu", (unsigned long)requestCount] action:^{
      [weakSelf showText:[MDBDebugInspector recentRequests] title:@"Requests"];
    }],
    [self rowWithTitle:@"Copy last request as cURL" detail:nil action:^{
      UIPasteboard.generalPasteboard.string = [MDBDebugInspector lastRequestAsCURL];
      [weakSelf toast:@"Copied, the token is redacted."];
    }],
  ];

  NSArray<NSString *> *levelNames = @[ @"Debug", @"Info", @"Error", @"Fault" ];
  MDBLogLevel level = MDBLogMinimumLevel();
  NSArray<MDBDebugRow *> *logs = @[
    [self rowWithTitle:@"Recent logs" detail:@"View" action:^{
      [weakSelf showText:[MDBDebugInspector recentLogs] title:@"Logs"];
    }],
    [self rowWithTitle:@"Minimum log level" detail:levelNames[(NSUInteger)level] action:^{
      MDBLogSetMinimumLevel((MDBLogLevel)(((NSInteger)MDBLogMinimumLevel() + 1) % 4));
      [weakSelf rebuild];
    }],
    [self rowWithTitle:@"MetricKit payloads"
                detail:[NSString stringWithFormat:@"%lu saved", (unsigned long)[deps.metrics savedPayloadURLs].count] action:^{
                  [weakSelf shareMetricPayloads];
                }],
  ];

  NSMutableArray<MDBDebugRow *> *tools = [NSMutableArray array];
#if MDB_HAS_FLEX
  [tools addObject:[self rowWithTitle:@"Open FLEX explorer" detail:nil action:^{
           [weakSelf dismissViewControllerAnimated:YES completion:^{
             [[FLEXManager sharedManager] showExplorer];
           }];
         }]];
#endif
  [tools addObject:[self rowWithTitle:@"Clear image cache" detail:nil action:^{
           [[SDImageCache sharedImageCache] clearMemory];
           [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
             [weakSelf toast:@"Image cache cleared."];
           }];
         }]];
  MDBDebugRow *clearFavorites = [self rowWithTitle:@"Delete all favorites" detail:nil action:^{
    [deps.favoritesStore removeAllFavoritesWithCompletion:^(NSError *error) {
      [weakSelf toast:error ? error.localizedDescription : @"Favorites deleted."];
    }];
  }];
  clearFavorites.destructive = YES;
  [tools addObject:clearFavorites];

  self.sectionTitles = @[ @"Status", @"Network", @"Logs and metrics", @"Tools" ];
  self.sections = @[ status, network, logs, tools ];
  [self.tableView reloadData];
}

#pragma mark - Helpers

- (void)showText:(NSString *)text title:(NSString *)title {
  MDBDebugTextViewController *viewer = [[MDBDebugTextViewController alloc] init];
  viewer.text = text;
  viewer.title = title;
  [self.navigationController pushViewController:viewer animated:YES];
}

- (void)toast:(NSString *)message {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [self presentViewController:alert animated:YES completion:nil];
  __weak UIAlertController *weakAlert = alert;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [weakAlert dismissViewControllerAnimated:YES completion:nil];
  });
}

- (void)shareMetricPayloads {
  NSArray<NSURL *> *files = [self.dependencies.metrics savedPayloadURLs];
  if (files.count == 0) {
    [self toast:@"No payloads yet. They arrive about once a day on a real device."];
    return;
  }
  UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:files applicationActivities:nil];
  activity.popoverPresentationController.sourceView = self.view;
  [self presentViewController:activity animated:YES completion:nil];
}

- (void)doneTapped {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (NSInteger)self.sections[(NSUInteger)section].count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return self.sectionTitles[(NSUInteger)section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Row" forIndexPath:indexPath];
  MDBDebugRow *row = self.sections[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
  UIListContentConfiguration *content = [UIListContentConfiguration valueCellConfiguration];
  content.text = row.title;
  content.secondaryText = row.detail;
  content.textProperties.color = row.destructive ? UIColor.mdb_danger : UIColor.mdb_textPrimary;
  content.secondaryTextProperties.color = UIColor.mdb_textSecondary;
  cell.contentConfiguration = content;
  cell.backgroundColor = UIColor.mdb_surface;
  cell.selectionStyle = row.action ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  MDBDebugRow *row = self.sections[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
  if (row.action) {
    row.action();
  }
}

@end

#endif
