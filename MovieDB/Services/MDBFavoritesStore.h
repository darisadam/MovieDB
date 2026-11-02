//
//  MDBFavoritesStore.h
//  MovieDB
//

#import <Foundation/Foundation.h>

@class MDBMovie;
@class MDBObservable<ObjectType>;

NS_ASSUME_NONNULL_BEGIN

/// Snapshot of a saved favorite. Safe to pass around, it isn't tied to a managed object context.
@interface MDBFavoriteMovie : NSObject

@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *overview;
@property (nonatomic, copy, readonly, nullable) NSString *posterPath;
@property (nonatomic, copy, readonly, nullable) NSDate *releaseDate;
@property (nonatomic, readonly) double voteAverage;
@property (nonatomic, readonly) NSInteger voteCount;
@property (nonatomic, copy, readonly) NSArray<NSString *> *genreNames;
@property (nonatomic, copy, readonly) NSDate *addedAt;

- (instancetype)initWithMovieID:(NSInteger)movieID
                          title:(NSString *)title
                       overview:(nullable NSString *)overview
                     posterPath:(nullable NSString *)posterPath
                    releaseDate:(nullable NSDate *)releaseDate
                    voteAverage:(double)voteAverage
                      voteCount:(NSInteger)voteCount
                     genreNames:(NSArray<NSString *> *)genreNames
                        addedAt:(NSDate *)addedAt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

typedef void (^MDBFavoritesCompletion)(NSError *_Nullable error);

@protocol MDBFavoritesStore <NSObject>

/// Every favorite, newest first. Replays on subscribe and emits on the main queue after each change.
@property (nonatomic, readonly) MDBObservable<NSArray<MDBFavoriteMovie *> *> *favorites;

- (BOOL)isFavoriteMovieID:(NSInteger)movieID;

- (void)addFavoriteMovie:(MDBMovie *)movie
              genreNames:(NSArray<NSString *> *)genreNames
              completion:(nullable MDBFavoritesCompletion)completion;
- (void)removeFavoriteWithMovieID:(NSInteger)movieID completion:(nullable MDBFavoritesCompletion)completion;
- (void)removeAllFavoritesWithCompletion:(nullable MDBFavoritesCompletion)completion;

@end

NS_ASSUME_NONNULL_END
