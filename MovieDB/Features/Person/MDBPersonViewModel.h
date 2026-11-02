//
//  MDBPersonViewModel.h
//  MovieDB
//

#import <Foundation/Foundation.h>
#import "MDBMovieService.h"

@class MDBImageURLBuilder;
@class MDBMovieCellModel;
@class MDBObservable<ObjectType>;
@class MDBScreenState<ContentType>;

NS_ASSUME_NONNULL_BEGIN

@interface MDBFilmographyRow : NSObject
@property (nonatomic, copy, readonly) NSString *yearText;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *roleText;
@property (nonatomic, readonly) MDBMovieCellModel *movie;
- (instancetype)initWithMovie:(MDBMovieCellModel *)movie roleText:(NSString *)roleText NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface MDBPersonFact : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *value;
- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface MDBPersonContent : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly, nullable) NSURL *profileURL;
@property (nonatomic, copy, readonly) NSString *departmentText;
@property (nonatomic, copy, readonly) NSArray<MDBPersonFact *> *facts;
@property (nonatomic, copy, readonly) NSString *biography;
@property (nonatomic, copy, readonly) NSArray<MDBMovieCellModel *> *knownFor;
@property (nonatomic, copy, readonly) NSArray<MDBFilmographyRow *> *filmography;
@end

typedef id<MDBPersonProviding, MDBGenreProviding> MDBPersonServices;

@interface MDBPersonViewModel : NSObject

/// While loading the content only has the name we were opened with.
@property (nonatomic, readonly) MDBObservable<MDBScreenState<MDBPersonContent *> *> *state;

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                        services:(MDBPersonServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)load;

/// Testing hook for the age shown next to the birthday.
@property (nonatomic, copy) NSDate *now;

@end

NS_ASSUME_NONNULL_END
