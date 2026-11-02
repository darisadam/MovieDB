//
//  MDBMovieCellModel.m
//  MovieDB
//

#import "MDBMovieCellModel.h"
#import "MDBFavoritesStore.h"
#import "MDBFormatting.h"
#import "MDBImageURLBuilder.h"
#import "MDBMovie.h"
#import "MDBMovieService.h"

@interface MDBMovieCellModel ()
@property (nonatomic, readwrite) NSInteger movieID;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *yearText;
@property (nonatomic, copy, readwrite) NSString *metaText;
@property (nonatomic, copy, readwrite) NSString *ratingText;
@property (nonatomic, readwrite) double rating;
@property (nonatomic, copy, readwrite) NSString *votesText;
@property (nonatomic, copy, readwrite) NSString *releaseDateText;
@property (nonatomic, copy, readwrite) NSString *overview;
@property (nonatomic, copy, readwrite, nullable) NSURL *posterURL;
@property (nonatomic, copy, readwrite, nullable) NSURL *smallPosterURL;
@property (nonatomic, copy, readwrite, nullable) NSURL *backdropURL;
@property (nonatomic, readwrite, nullable) MDBMovie *movie;
@end

@implementation MDBMovieCellModel

- (instancetype)initPrivate {
  return [super init];
}

+ (NSString *)metaTextWithYear:(NSString *)year genres:(NSArray<NSString *> *)genres {
  NSString *genreText =
      [[genres subarrayWithRange:NSMakeRange(0, MIN(genres.count, (NSUInteger)3))] componentsJoinedByString:@", "];
  if (year.length > 0 && genreText.length > 0) {
    return [NSString stringWithFormat:@"%@ · %@", year, genreText];
  }
  return year.length > 0 ? year : genreText;
}

+ (NSString *)votesTextWithCount:(NSInteger)count {
  if (count <= 0) {
    return @"";
  }
  NSString *unit = count == 1 ? @"vote" : @"votes";
  return [NSString stringWithFormat:@"(%@ %@)", [MDBFormatting compactCountStringFromCount:count], unit];
}

+ (instancetype)modelWithMovie:(MDBMovie *)movie
                    genreNames:(NSArray<NSString *> *)genreNames
                     imageURLs:(MDBImageURLBuilder *)imageURLs {
  MDBMovieCellModel *model = [[self alloc] initPrivate];
  model.movieID = movie.movieID;
  model.title = movie.title;
  model.yearText = [MDBFormatting yearStringFromDate:movie.releaseDate];
  model.metaText = [self metaTextWithYear:model.yearText genres:genreNames];
  model.rating = movie.voteCount > 0 ? movie.voteAverage : 0;
  model.ratingText = [MDBFormatting ratingStringFromVoteAverage:model.rating];
  model.votesText = [self votesTextWithCount:movie.voteCount];
  model.releaseDateText = [MDBFormatting mediumDateStringFromDate:movie.releaseDate];
  model.overview = movie.overview ?: @"";
  model.posterURL = [imageURLs URLForPath:movie.posterPath size:MDBImageSizePoster];
  model.smallPosterURL = [imageURLs URLForPath:movie.posterPath size:MDBImageSizePosterSmall];
  model.backdropURL = [imageURLs URLForPath:movie.backdropPath size:MDBImageSizeBackdrop];
  model.movie = movie;
  return model;
}

+ (instancetype)modelWithFavorite:(MDBFavoriteMovie *)favorite imageURLs:(MDBImageURLBuilder *)imageURLs {
  MDBMovie *movie = [[MDBMovie alloc] initWithMovieID:favorite.movieID title:favorite.title overview:favorite.overview
                                           posterPath:favorite.posterPath
                                         backdropPath:nil
                                          releaseDate:favorite.releaseDate
                                          voteAverage:favorite.voteAverage
                                            voteCount:favorite.voteCount
                                           popularity:0
                                             genreIDs:nil];
  return [self modelWithMovie:movie genreNames:favorite.genreNames imageURLs:imageURLs];
}

+ (NSArray<MDBMovieCellModel *> *)modelsWithMovies:(NSArray<MDBMovie *> *)movies
                                        genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames
                                         imageURLs:(MDBImageURLBuilder *)imageURLs {
  NSMutableArray<MDBMovieCellModel *> *models = [NSMutableArray arrayWithCapacity:movies.count];
  for (MDBMovie *movie in movies) {
    NSArray<NSString *> *names = MDBGenreNamesForIDs(genreNames, movie.genreIDs);
    [models addObject:[self modelWithMovie:movie genreNames:names imageURLs:imageURLs]];
  }
  return [models copy];
}

- (NSString *)accessibilityLabelText {
  NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObject:self.title];
  if (self.yearText.length > 0) {
    [parts addObject:self.yearText];
  }
  if (self.rating > 0) {
    [parts addObject:[NSString stringWithFormat:@"rated %@", self.ratingText]];
  }
  return [parts componentsJoinedByString:@", "];
}

@end
