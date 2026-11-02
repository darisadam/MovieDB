//
//  MDBPersonViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBLoadState.h"
#import "MDBMovieService.h"

@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBPerson;

NS_ASSUME_NONNULL_BEGIN

@interface MDBFilmographyRow : NSObject
@property (nonatomic, readonly) NSInteger movieID;
@property (nonatomic, copy, readonly) NSString *yearText;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *roleText;
@property (nonatomic, readonly) MDBMovieCellModel *movie;
- (instancetype)initWithMovie:(MDBMovieCellModel *)movie roleText:(NSString *)roleText NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface MDBPersonViewModel : NSObject

@property (nonatomic, readonly) MDBLoadState state;
@property (nonatomic, readonly, nullable) NSError *error;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly, nullable) NSURL *profileURL;
@property (nonatomic, copy, readonly) NSString *departmentText;
/// Label and value pairs like Born, Place of birth.
@property (nonatomic, copy, readonly) NSArray<NSArray<NSString *> *> *facts;
@property (nonatomic, copy, readonly) NSString *biography;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *knownFor;
@property (nonatomic, copy, readonly) NSArray<MDBFilmographyRow *> *filmography;

@property (nonatomic, copy, nullable) void (^onChange)(void);

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                    movieService:(id<MDBMovieService>)movieService
                       imageURLs:(MDBImageURLBuilder *)imageURLs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)load;

@end

NS_ASSUME_NONNULL_END
