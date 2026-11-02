//
//  MDBFavoritesViewModel.m
//  MovieDB
//

#import "MDBFavoritesViewModel.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovieCellModel.h"

@interface MDBFavoritesViewModel ()
@property (nonatomic, readwrite) MDBLoadState state;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) NSNotificationCenter *notificationCenter;
@property (nonatomic) id favoritesObserver;
@end

@implementation MDBFavoritesViewModel

- (instancetype)initWithFavoritesStore:(id<MDBFavoritesStore>)favoritesStore
                             imageURLs:(MDBImageURLBuilder *)imageURLs
                    notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (self) {
        _favoritesStore = favoritesStore;
        _imageURLs = imageURLs;
        _notificationCenter = notificationCenter;
        _items = @[];

        __weak typeof(self) weakSelf = self;
        _favoritesObserver = [notificationCenter addObserverForName:MDBFavoritesDidChangeNotification
                                                             object:nil
                                                              queue:[NSOperationQueue mainQueue]
                                                         usingBlock:^(NSNotification *note) {
            [weakSelf reload];
        }];
    }
    return self;
}

- (void)dealloc {
    if (_favoritesObserver) {
        [_notificationCenter removeObserver:_favoritesObserver];
    }
}

- (void)reload {
    MDBAssertMainThread();
    NSArray<MDBFavoriteMovie *> *favorites = [self.favoritesStore allFavorites];
    NSMutableArray<MDBMovieCellModel *> *items = [NSMutableArray arrayWithCapacity:favorites.count];
    for (MDBFavoriteMovie *favorite in favorites) {
        [items addObject:[MDBMovieCellModel modelWithFavorite:favorite imageURLs:self.imageURLs]];
    }
    self.items = items;
    self.state = items.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
    if (self.onChange) {
        self.onChange();
    }
}

- (void)removeItemAtIndex:(NSUInteger)index {
    if (index >= self.items.count) {
        MDBLogFault(MDBLogCategoryUI, @"Tried to remove favorite at %lu but only %lu exist",
                    (unsigned long)index, (unsigned long)self.items.count);
        return;
    }
    MDBMovieCellModel *item = self.items[index];
    // Update the list right away so the row animation lines up, the store catches up in the background.
    NSMutableArray<MDBMovieCellModel *> *items = [self.items mutableCopy];
    [items removeObjectAtIndex:index];
    self.items = items;
    self.state = items.count > 0 ? MDBLoadStateLoaded : MDBLoadStateEmpty;
    [self.favoritesStore removeFavoriteWithMovieID:item.movieID completion:nil];
}

- (NSString *)summaryText {
    NSUInteger count = self.items.count;
    return [NSString stringWithFormat:@"%lu %@ · saved on this device", (unsigned long)count, count == 1 ? @"movie" : @"movies"];
}

@end
