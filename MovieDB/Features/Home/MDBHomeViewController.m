//
//  MDBHomeViewController.m
//  MovieDB
//

#import "MDBHomeViewController.h"
#import "MDBCarouselCell.h"
#import "MDBHomeViewModel.h"
#import "MDBLayoutFactory.h"
#import "MDBLog.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPosterCell.h"
#import "MDBScreenState.h"
#import "MDBSectionHeaderView.h"
#import "MDBSignpost.h"
#import "MDBSkeletonView.h"
#import "MDBStateView.h"
#import "MDBTheme.h"
#import "UIView+MDBLayout.h"

static const CGFloat MDBCarouselHeight = 250;

@interface MDBHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) MDBHomeViewModel *viewModel;
@property (nonatomic, readonly) MDBDisposeBag *bag;
@property (nonatomic) MDBHomeContent *content;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) UIView *skeletonView;
@property (nonatomic) MDBStateView *stateView;
@property (nonatomic) os_signpost_id_t loadSignpost;
@property (nonatomic) BOOL hasFinishedFirstLoad;
@end

@implementation MDBHomeViewController

- (instancetype)initWithViewModel:(MDBHomeViewModel *)viewModel {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = viewModel;
    _bag = [[MDBDisposeBag alloc] init];
    _content = [[MDBHomeContent alloc] initWithCarouselItems:@[] sections:@[]];
    self.title = @"Home";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.loadSignpost = [MDBSignpost beginScreenLoad:@"Home"];
  self.view.backgroundColor = UIColor.mdb_background;
  [self setUpNavigationItem];
  [self setUpCollectionView];
  [self setUpOverlays];

  __weak typeof(self) weakSelf = self;
  [self.bag addDisposable:[self.viewModel.state subscribe:^(MDBScreenState<MDBHomeContent *> *state) {
              [weakSelf render:state];
            }]];
  [self.viewModel loadIfNeeded];
}

#pragma mark - Setup

- (void)setUpNavigationItem {
  UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
  logo.contentMode = UIViewContentModeScaleAspectFit;
  logo.translatesAutoresizingMaskIntoConstraints = NO;
  [logo.heightAnchor constraintEqualToConstant:26].active = YES;
  [logo.widthAnchor constraintEqualToConstant:100].active = YES;
  logo.isAccessibilityElement = YES;
  logo.accessibilityLabel = @"MovieDB";
  logo.accessibilityTraits = UIAccessibilityTraitHeader;
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logo];
  self.navigationItem.title = @"";
  self.navigationItem.backButtonDisplayMode = UINavigationItemBackButtonDisplayModeMinimal;
}

- (void)setUpCollectionView {
  __weak typeof(self) weakSelf = self;
  UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc]
      initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger section, id<NSCollectionLayoutEnvironment> environment) {
        return [weakSelf layoutSectionAtIndex:section];
      }];

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.collectionView.backgroundColor = UIColor.mdb_background;
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.alwaysBounceVertical = YES;
  [self.collectionView registerClass:[MDBCarouselCell class] forCellWithReuseIdentifier:MDBCarouselCell.identifier];
  [self.collectionView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
  [self.collectionView registerClass:[MDBSectionHeaderView class] forSupplementaryViewOfKind:MDBSectionHeaderKind
                 withReuseIdentifier:MDBSectionHeaderView.identifier];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
  self.collectionView.refreshControl = self.refreshControl;

  [self.view addSubview:self.collectionView];
  self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
    [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)setUpOverlays {
  self.skeletonView = [self makeSkeletonView];
  self.stateView = [[MDBStateView alloc] initWithFrame:CGRectZero];
  __weak typeof(self) weakSelf = self;
  self.stateView.onAction = ^{
    [weakSelf.viewModel reload];
  };

  for (UIView *overlay in @[ self.skeletonView, self.stateView ]) {
    [self.view addSubview:overlay];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
      [overlay.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [overlay.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
      [overlay.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
      [overlay.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
  }
}

- (UIView *)makeSkeletonView {
  UIView *container = [[UIView alloc] init];
  container.backgroundColor = UIColor.mdb_background;
  container.clipsToBounds = YES;
  container.isAccessibilityElement = YES;
  container.accessibilityLabel = @"Loading movies";

  MDBSkeletonView *hero = [MDBSkeletonView blockWithCornerRadius:0];
  [container addSubview:hero];
  [NSLayoutConstraint activateConstraints:@[
    [hero.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
    [hero.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
    [hero.topAnchor constraintEqualToAnchor:container.topAnchor],
    [hero.heightAnchor constraintEqualToConstant:MDBCarouselHeight],
  ]];

  UIView *previous = hero;
  for (NSInteger row = 0; row < 2; row++) {
    MDBSkeletonView *header = [MDBSkeletonView blockWithCornerRadius:4];
    [container addSubview:header];
    [NSLayoutConstraint activateConstraints:@[
      [header.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20],
      [header.topAnchor constraintEqualToAnchor:previous.bottomAnchor constant:28],
      [header.widthAnchor constraintEqualToConstant:130],
      [header.heightAnchor constraintEqualToConstant:16],
    ]];
    UIView *lastPoster = nil;
    for (NSInteger column = 0; column < 4; column++) {
      MDBSkeletonView *poster = [MDBSkeletonView blockWithCornerRadius:6];
      [container addSubview:poster];
      NSLayoutXAxisAnchor *leading = lastPoster ? lastPoster.trailingAnchor : container.leadingAnchor;
      [NSLayoutConstraint activateConstraints:@[
        [poster.leadingAnchor constraintEqualToAnchor:leading constant:lastPoster ? 8 : 20],
        [poster.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:16],
        [poster.widthAnchor constraintEqualToConstant:102],
        [poster.heightAnchor constraintEqualToConstant:153],
      ]];
      lastPoster = poster;
    }
    previous = lastPoster ?: header;
  }
  return container;
}

#pragma mark - Rendering

- (void)render:(MDBScreenState<MDBHomeContent *> *)state {
  MDBHomeContent *content = state.content;
  if (content) {
    self.content = content;
  }
  BOOL hasContent = self.content.carouselItems.count > 0 || self.content.sections.count > 0;

  self.skeletonView.hidden = hasContent || !(state.isLoading || state.phase == MDBLoadStateIdle);
  self.stateView.hidden = YES;
  NSError *error = state.error;
  if (state.phase == MDBLoadStateEmpty) {
    self.stateView.hidden = NO;
    [self.stateView configureWithSymbolName:@"film.stack" title:@"Nothing to show yet"
                                    message:@"TMDB didn't return any movies for your region. Try another region in Menu."
                                actionTitle:@"Try Again"
                           actionSymbolName:@"arrow.clockwise"];
  } else if (state.phase == MDBLoadStateFailed && error && !hasContent) {
    self.stateView.hidden = NO;
    [self.stateView configureWithError:error];
  }

  if (!state.isLoading) {
    [self.refreshControl endRefreshing];
    [self markFirstLoadFinishedIfNeeded:state];
  }
  [self.collectionView reloadData];
}

- (void)markFirstLoadFinishedIfNeeded:(MDBScreenState *)state {
  if (self.hasFinishedFirstLoad || state.phase == MDBLoadStateIdle) {
    return;
  }
  self.hasFinishedFirstLoad = YES;
  [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Home"];
}

- (void)pullToRefresh {
  MDBLogDebug(MDBLogCategoryUI, @"Home pull to refresh");
  [self.viewModel reload];
}

#pragma mark - Section mapping

- (BOOL)hasCarousel {
  return self.content.carouselItems.count > 0;
}

/// Index into content.sections, or -1 for the carousel.
- (NSInteger)rowIndexForSection:(NSInteger)section {
  return self.hasCarousel ? section - 1 : section;
}

- (nullable MDBHomeSection *)homeSectionAtIndex:(NSInteger)section {
  NSInteger rowIndex = [self rowIndexForSection:section];
  NSArray<MDBHomeSection *> *sections = self.content.sections;
  return rowIndex >= 0 && rowIndex < (NSInteger)sections.count ? sections[(NSUInteger)rowIndex] : nil;
}

- (nullable NSCollectionLayoutSection *)layoutSectionAtIndex:(NSInteger)section {
  if ([self rowIndexForSection:section] < 0) {
    return [MDBLayoutFactory carouselSectionWithHeight:MDBCarouselHeight];
  }
  BOOL isUpcoming = [self homeSectionAtIndex:section].kind == MDBMovieListKindUpcoming;
  CGSize itemSize = CGSizeMake(102, isUpcoming ? 176 : 153);
  return [MDBLayoutFactory horizontalRowSectionWithItemSize:itemSize spacing:8 hasHeader:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return (NSInteger)self.content.sections.count + (self.hasCarousel ? 1 : 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if ([self rowIndexForSection:section] < 0) {
    return (NSInteger)self.content.carouselItems.count;
  }
  return (NSInteger)[self homeSectionAtIndex:section].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self rowIndexForSection:indexPath.section] < 0) {
    MDBCarouselCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBCarouselCell.identifier
                                                                      forIndexPath:indexPath];
    [cell configureWithModel:self.content.carouselItems[(NSUInteger)indexPath.item] pageIndex:indexPath.item
                   pageCount:(NSInteger)self.content.carouselItems.count];
    return cell;
  }
  MDBHomeSection *section = [self homeSectionAtIndex:indexPath.section];
  MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
  MDBPosterCellStyle style = section.kind == MDBMovieListKindUpcoming ? MDBPosterCellStyleDated : MDBPosterCellStylePlain;
  MDBMovieCellModel *model = section.items[(NSUInteger)indexPath.item];
  [cell configureWithModel:model style:style];
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
  MDBSectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                    withReuseIdentifier:MDBSectionHeaderView.identifier
                                                                           forIndexPath:indexPath];
  MDBHomeSection *section = [self homeSectionAtIndex:indexPath.section];
  if (section) {
    [header configureWithTitle:section.title showsSeeAll:YES];
    MDBMovieListKind sectionKind = section.kind;
    __weak typeof(self) weakSelf = self;
    header.onSeeAll = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf.delegate homeViewController:strongSelf didSelectSeeAllForKind:sectionKind];
      }
    };
  }
  return header;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  MDBMovieCellModel *model = [self rowIndexForSection:indexPath.section] < 0
                                 ? self.content.carouselItems[(NSUInteger)indexPath.item]
                                 : [self homeSectionAtIndex:indexPath.section].items[(NSUInteger)indexPath.item];
  MDBLogDebug(MDBLogCategoryUI, @"Home selected %@", model.title);
  [self.delegate homeViewController:self didSelectMovie:model];
}

@end
