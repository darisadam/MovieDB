//
//  MDBFavoritesViewModel.m
//  MovieDB
//

#import "MDBFavoritesViewModel.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBScreenState.h"

@interface MDBFavoritesViewModel ()
@property (nonatomic, readwrite) MDBObservable<MDBScreenState<NSArray<MDBMovieCellModel *> *> *> *state;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@end

@implementation MDBFavoritesViewModel

- (instancetype)initWithFavoritesStore:(id<MDBFavoritesStore>)favoritesStore imageURLs:(MDBImageURLBuilder *)imageURLs {
  self = [super init];
  if (self) {
    _favoritesStore = favoritesStore;
    _state = [favoritesStore.favorites map:^id(NSArray<MDBFavoriteMovie *> *favorites) {
      if (favorites.count == 0) {
        return [MDBScreenState empty];
      }
      NSMutableArray<MDBMovieCellModel *> *items = [NSMutableArray arrayWithCapacity:favorites.count];
      for (MDBFavoriteMovie *favorite in favorites) {
        [items addObject:[MDBMovieCellModel modelWithFavorite:favorite imageURLs:imageURLs]];
      }
      return [MDBScreenState loadedWithContent:[items copy]];
    }];
  }
  return self;
}

- (void)removeMovieWithID:(NSInteger)movieID {
  [self.favoritesStore removeFavoriteWithMovieID:movieID completion:nil];
}

+ (NSString *)summaryForCount:(NSUInteger)count {
  return [NSString stringWithFormat:@"%lu %@ · saved on this device", (unsigned long)count, count == 1 ? @"movie" : @"movies"];
}

@end
