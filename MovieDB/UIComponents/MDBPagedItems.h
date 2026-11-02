//
//  MDBPagedItems.h
//  MovieDB
//
//  Display version of MDBPagedMovies, shared by search results, See All and genre results.
//

#import <Foundation/Foundation.h>

@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBPagedMovies;

NS_ASSUME_NONNULL_BEGIN

@interface MDBPagedItems : NSObject

@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *items;
@property (nonatomic, readonly) NSInteger totalResults;
@property (nonatomic, readonly, getter=isLoadingMore) BOOL loadingMore;

+ (instancetype)itemsFromPage:(MDBPagedMovies *)page
                   genreNames:(nullable NSDictionary<NSNumber *, NSString *> *)genreNames
                    imageURLs:(MDBImageURLBuilder *)imageURLs;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
