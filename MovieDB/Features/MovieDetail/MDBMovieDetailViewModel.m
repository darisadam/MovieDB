//
//  MDBMovieDetailViewModel.m
//  MovieDB
//

#import "MDBMovieDetailViewModel.h"
#import "MDBAPIError.h"
#import "MDBCastCell.h"
#import "MDBCastMember.h"
#import "MDBFormatting.h"
#import "MDBGenre.h"
#import "MDBImageURLBuilder.h"
#import "MDBLog.h"
#import "MDBMacros.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBMovieDetail.h"
#import "MDBObservable.h"
#import "MDBScreenState.h"
#import "MDBVideo.h"

@implementation MDBMovieFact

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value {
  self = [super init];
  if (self) {
    _title = [title copy];
    _value = [value copy];
  }
  return self;
}

@end

@interface MDBMovieDetailContent ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite, nullable) NSURL *backdropURL;
@property (nonatomic, copy, readwrite) NSString *metaText;
@property (nonatomic, copy, readwrite, nullable) NSString *ratingText;
@property (nonatomic, copy, readwrite, nullable) NSString *tagline;
@property (nonatomic, copy, readwrite) NSString *overview;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *genreNames;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieFact *> *facts;
@property (nonatomic, copy, readwrite) NSArray<MDBCastCellModel *> *cast;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *recommendations;
@property (nonatomic, copy, readwrite) NSArray<MDBVideo *> *videos;
@property (nonatomic, readwrite, getter=isComplete) BOOL complete;
@end

@implementation MDBMovieDetailContent

- (BOOL)hasTrailer {
  return self.videos.count > 0;
}

/// Builds the content from the full detail when we have it, otherwise from the seed movie.
+ (instancetype)contentWithMovie:(MDBMovie *)movie
                          detail:(nullable MDBMovieDetail *)detail
                      genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames
                       imageURLs:(MDBImageURLBuilder *)imageURLs {
  MDBMovieDetailContent *content = [[self alloc] init];
  content.title = movie.title;
  // A tall poster looks better than a cropped backdrop in this header.
  content.backdropURL = [imageURLs URLForPath:movie.posterPath size:MDBImageSizeBackdrop]
                            ?: [imageURLs URLForPath:movie.backdropPath size:MDBImageSizeBackdrop];
  content.metaText = [self metaTextForMovie:movie runtime:detail.runtimeMinutes];
  content.ratingText = movie.voteCount > 0 ? [MDBFormatting ratingStringFromVoteAverage:movie.voteAverage] : nil;
  content.tagline = detail.tagline;
  content.overview = movie.overview.length > 0 ? (NSString *_Nonnull)movie.overview : @"No overview yet.";
  content.genreNames = detail ? [detail.genres valueForKey:@"name"] : MDBGenreNamesForIDs(genreNames, movie.genreIDs);
  content.facts = detail ? [self factsForDetail:detail] : @[];
  content.cast = [self castModelsForDetail:detail imageURLs:imageURLs];
  content.recommendations = [MDBMovieCellModel modelsWithMovies:detail.recommendations ?: @[] genreNames:genreNames
                                                      imageURLs:imageURLs];
  content.videos = detail.videos ?: @[];
  content.complete = detail != nil;
  return content;
}

+ (NSString *)metaTextForMovie:(MDBMovie *)movie runtime:(NSInteger)runtime {
  NSMutableArray<NSString *> *parts = [NSMutableArray array];
  NSString *year = [MDBFormatting yearStringFromDate:movie.releaseDate];
  NSString *length = [MDBFormatting runtimeStringFromMinutes:runtime];
  if (year.length > 0) {
    [parts addObject:year];
  }
  if (length.length > 0) {
    [parts addObject:length];
  }
  return [parts componentsJoinedByString:@"  ·  "];
}

+ (NSArray<MDBMovieFact *> *)factsForDetail:(MDBMovieDetail *)detail {
  NSMutableArray<MDBMovieFact *> *facts = [NSMutableArray array];
  NSString *release = [MDBFormatting mediumDateStringFromDate:detail.movie.releaseDate];
  [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Release" value:release.length > 0 ? release : @"TBA"]];
  NSString *language = detail.originalLanguageName;
  if (language.length > 0) {
    [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Language" value:language]];
  }
  NSString *budget = [MDBFormatting compactCurrencyStringFromAmount:detail.budget];
  NSString *status = detail.status;
  if (budget.length > 0) {
    [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Budget" value:budget]];
  } else if (status.length > 0) {
    [facts addObject:[[MDBMovieFact alloc] initWithTitle:@"Status" value:status]];
  }
  return facts;
}

+ (NSArray<MDBCastCellModel *> *)castModelsForDetail:(nullable MDBMovieDetail *)detail imageURLs:(MDBImageURLBuilder *)imageURLs {
  NSMutableArray<MDBCastCellModel *> *models = [NSMutableArray array];
  for (MDBCastMember *member in detail.cast) {
    NSURL *photo = [imageURLs URLForPath:member.profilePath size:MDBImageSizeProfile];
    [models addObject:[[MDBCastCellModel alloc] initWithPersonID:member.personID name:member.name character:member.character
                                                        photoURL:photo]];
  }
  return models;
}

@end

@interface MDBMovieDetailViewModel ()
@property (nonatomic, readonly, nullable) MDBMovie *seedMovie;
@property (nonatomic, readonly) MDBMovieDetailServices services;
@property (nonatomic, readonly) id<MDBFavoritesStore> favoritesStore;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) MDBSubject<MDBScreenState<MDBMovieDetailContent *> *> *subject;
@property (nonatomic, readwrite) MDBObservable<NSNumber *> *isFavorite;
@property (nonatomic, nullable) MDBMovieDetail *detail;
@property (nonatomic, nullable) id<MDBCancellable> task;
@end

@implementation MDBMovieDetailViewModel

- (instancetype)initWithMovieID:(NSInteger)movieID
                      seedMovie:(nullable MDBMovie *)seedMovie
                       services:(MDBMovieDetailServices)services
                 favoritesStore:(id<MDBFavoritesStore>)favoritesStore
                      imageURLs:(MDBImageURLBuilder *)imageURLs {
  self = [super init];
  if (self) {
    _movieID = movieID;
    _seedMovie = seedMovie;
    _services = services;
    _favoritesStore = favoritesStore;
    _imageURLs = imageURLs;
    _subject = [[MDBSubject alloc] initWithValue:[MDBScreenState loadingWithContent:[self seedContent]]];
    _isFavorite = [[favoritesStore.favorites map:^id(NSArray<MDBFavoriteMovie *> *favorites) {
      for (MDBFavoriteMovie *favorite in favorites) {
        if (favorite.movieID == movieID) {
          return @YES;
        }
      }
      return @NO;
    }] distinctUntilChanged];
  }
  return self;
}

- (void)dealloc {
  [_task cancel];
}

- (MDBObservable<MDBScreenState<MDBMovieDetailContent *> *> *)state {
  return self.subject;
}

- (nullable MDBMovieDetailContent *)seedContent {
  MDBMovie *seed = self.seedMovie;
  if (!seed) {
    return nil;
  }
  return [MDBMovieDetailContent contentWithMovie:seed detail:nil genreNames:self.services.genreNames.value
                                       imageURLs:self.imageURLs];
}

- (void)load {
  MDBAssertMainThread();
  [self.task cancel];
  [self.subject send:[MDBScreenState loadingWithContent:self.subject.value.content ?: [self seedContent]]];

  __weak typeof(self) weakSelf = self;
  self.task = [self.services fetchMovieDetailWithID:self.movieID completion:^(MDBMovieDetail *detail, NSError *error) {
    [weakSelf handleDetail:detail error:error];
  }];
}

- (void)handleDetail:(nullable MDBMovieDetail *)detail error:(nullable NSError *)error {
  if (error.mdb_isCancelled) {
    return;
  }
  MDBMovieDetail *loaded = detail;
  if (!loaded) {
    [self.subject send:[MDBScreenState failedWithError:error content:[self seedContent]]];
    return;
  }
  self.detail = loaded;
  MDBLogInfo(MDBLogCategoryUI, @"Detail loaded %@", loaded);
  MDBMovieDetailContent *content = [MDBMovieDetailContent contentWithMovie:loaded.movie detail:loaded
                                                                genreNames:self.services.genreNames.value
                                                                 imageURLs:self.imageURLs];
  [self.subject send:[MDBScreenState loadedWithContent:content]];
}

- (void)toggleFavorite {
  MDBMovie *movie = self.detail.movie ?: self.seedMovie;
  if (!movie) {
    return;
  }
  if ([self.isFavorite.value boolValue]) {
    [self.favoritesStore removeFavoriteWithMovieID:self.movieID completion:nil];
  } else {
    [self.favoritesStore addFavoriteMovie:movie genreNames:self.subject.value.content.genreNames ?: @[] completion:nil];
  }
}

- (nullable NSURL *)shareURL {
  return [NSURL URLWithString:[NSString stringWithFormat:@"https://www.themoviedb.org/movie/%ld", (long)self.movieID]];
}

@end
