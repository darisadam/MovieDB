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
#import "MDBPosterCell.h"
#import "MDBSectionHeaderView.h"
#import "MDBSignpost.h"
#import "MDBSkeletonView.h"
#import "MDBStateView.h"
#import "MDBTheme.h"

static const CGFloat MDBCarouselHeight = 250;

@interface MDBHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, readonly) MDBHomeViewModel *viewModel;
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
    self.viewModel.onChange = ^{
        [weakSelf render];
    };
    [self render];
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
    UICollectionViewCompositionalLayout *layout =
        [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger section, id<NSCollectionLayoutEnvironment> environment) {
            return [weakSelf layoutSectionAtIndex:section];
        }];

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.mdb_background;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    [self.collectionView registerClass:[MDBCarouselCell class] forCellWithReuseIdentifier:MDBCarouselCell.identifier];
    [self.collectionView registerClass:[MDBPosterCell class] forCellWithReuseIdentifier:MDBPosterCell.identifier];
    [self.collectionView registerClass:[MDBSectionHeaderView class]
            forSupplementaryViewOfKind:MDBSectionHeaderKind
                   withReuseIdentifier:MDBSectionHeaderView.identifier];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = self.refreshControl;

    [self.view addSubview:self.collectionView];
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

    for (UIView *overlay in @[self.skeletonView, self.stateView]) {
        [self.view addSubview:overlay];
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
    container.translatesAutoresizingMaskIntoConstraints = NO;
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
            [NSLayoutConstraint activateConstraints:@[
                [poster.leadingAnchor constraintEqualToAnchor:lastPoster ? lastPoster.trailingAnchor : container.leadingAnchor
                                                    constant:lastPoster ? 8 : 20],
                [poster.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:16],
                [poster.widthAnchor constraintEqualToConstant:102],
                [poster.heightAnchor constraintEqualToConstant:153],
            ]];
            lastPoster = poster;
        }
        previous = lastPoster;
    }
    return container;
}

#pragma mark - Rendering

- (void)render {
    MDBHomeViewModel *viewModel = self.viewModel;
    BOOL hasContent = viewModel.carouselItems.count > 0 || viewModel.sections.count > 0;

    switch (viewModel.state) {
        case MDBLoadStateIdle:
        case MDBLoadStateLoading:
            self.skeletonView.hidden = hasContent;
            self.stateView.hidden = YES;
            break;
        case MDBLoadStateLoaded:
            self.skeletonView.hidden = YES;
            self.stateView.hidden = YES;
            break;
        case MDBLoadStateEmpty:
            self.skeletonView.hidden = YES;
            self.stateView.hidden = NO;
            [self.stateView configureWithSymbolName:@"film.stack"
                                              title:@"Nothing to show yet"
                                            message:@"TMDB didn't return any movies for your region. Try another region in Menu."
                                        actionTitle:@"Try Again"
                                   actionSymbolName:@"arrow.clockwise"];
            break;
        case MDBLoadStateFailed: {
            self.skeletonView.hidden = YES;
            self.stateView.hidden = hasContent;
            NSError *error = viewModel.error;
            if (error) {
                [self.stateView configureWithError:error];
            }
            break;
        }
    }

    if (viewModel.state != MDBLoadStateLoading) {
        [self.refreshControl endRefreshing];
        if (!self.hasFinishedFirstLoad) {
            self.hasFinishedFirstLoad = YES;
            [MDBSignpost endScreenLoad:self.loadSignpost screenName:@"Home"];
        }
    }
    [self.collectionView reloadData];
}

- (void)pullToRefresh {
    MDBLogDebug(MDBLogCategoryUI, @"Home pull to refresh");
    [self.viewModel reload];
}

#pragma mark - Section mapping

- (BOOL)hasCarousel {
    return self.viewModel.carouselItems.count > 0;
}

/// Index into viewModel.sections, or -1 for the carousel.
- (NSInteger)rowIndexForSection:(NSInteger)section {
    return self.hasCarousel ? section - 1 : section;
}

- (nullable NSCollectionLayoutSection *)layoutSectionAtIndex:(NSInteger)section {
    NSInteger rowIndex = [self rowIndexForSection:section];
    if (rowIndex < 0) {
        return [MDBLayoutFactory carouselSectionWithHeight:MDBCarouselHeight];
    }
    BOOL isUpcoming = rowIndex < (NSInteger)self.viewModel.sections.count
        && self.viewModel.sections[(NSUInteger)rowIndex].kind == MDBMovieListKindUpcoming;
    CGSize itemSize = CGSizeMake(102, isUpcoming ? 176 : 153);
    return [MDBLayoutFactory horizontalRowSectionWithItemSize:itemSize spacing:8 hasHeader:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return (NSInteger)self.viewModel.sections.count + (self.hasCarousel ? 1 : 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger rowIndex = [self rowIndexForSection:section];
    if (rowIndex < 0) {
        return (NSInteger)self.viewModel.carouselItems.count;
    }
    return (NSInteger)self.viewModel.sections[(NSUInteger)rowIndex].items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowIndex = [self rowIndexForSection:indexPath.section];
    if (rowIndex < 0) {
        MDBCarouselCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBCarouselCell.identifier forIndexPath:indexPath];
        [cell configureWithModel:self.viewModel.carouselItems[(NSUInteger)indexPath.item]
                       pageIndex:indexPath.item
                       pageCount:(NSInteger)self.viewModel.carouselItems.count];
        return cell;
    }
    MDBHomeSection *section = self.viewModel.sections[(NSUInteger)rowIndex];
    MDBPosterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MDBPosterCell.identifier forIndexPath:indexPath];
    MDBPosterCellStyle style = section.kind == MDBMovieListKindUpcoming ? MDBPosterCellStyleDated : MDBPosterCellStylePlain;
    [cell configureWithModel:section.items[(NSUInteger)indexPath.item] style:style];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    MDBSectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                      withReuseIdentifier:MDBSectionHeaderView.identifier
                                                                             forIndexPath:indexPath];
    NSInteger rowIndex = [self rowIndexForSection:indexPath.section];
    if (rowIndex >= 0 && rowIndex < (NSInteger)self.viewModel.sections.count) {
        MDBHomeSection *section = self.viewModel.sections[(NSUInteger)rowIndex];
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
    NSInteger rowIndex = [self rowIndexForSection:indexPath.section];
    MDBMovieCellModel *model = rowIndex < 0
        ? self.viewModel.carouselItems[(NSUInteger)indexPath.item]
        : self.viewModel.sections[(NSUInteger)rowIndex].items[(NSUInteger)indexPath.item];
    MDBLogDebug(MDBLogCategoryUI, @"Home selected %@", model.title);
    [self.delegate homeViewController:self didSelectMovie:model];
}

@end
