//
//  MDBPagedItems.m
//  MovieDB
//

#import "MDBPagedItems.h"
#import "MDBMovieCellModel.h"
#import "MDBMoviePager.h"

@implementation MDBPagedItems

+ (instancetype)itemsFromPage:(MDBPagedMovies *)page
                   genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames
                    imageURLs:(MDBImageURLBuilder *)imageURLs {
  MDBPagedItems *result = [[self alloc] initPrivate];
  result->_items = [MDBMovieCellModel modelsWithMovies:page.movies genreNames:genreNames imageURLs:imageURLs];
  result->_totalResults = page.totalResults;
  result->_loadingMore = page.isLoadingMore;
  return result;
}

- (instancetype)initPrivate {
  return [super init];
}

@end
