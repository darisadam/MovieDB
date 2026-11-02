//
//  MDBScreenState.h
//  MovieDB
//
//  What a screen shows at one moment: a phase, its content and an error.
//  View models publish these through an MDBObservable, view controllers render them.
//

#import <Foundation/Foundation.h>
#import "MDBLoadState.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDBScreenState<__covariant ContentType> : NSObject

@property (nonatomic, readonly) MDBLoadState phase;
@property (nonatomic, readonly, nullable) ContentType content;
@property (nonatomic, readonly, nullable) NSError *error;

+ (instancetype)idle;
/// Loading, optionally still showing what was there before.
+ (instancetype)loadingWithContent:(nullable ContentType)content;
+ (instancetype)loadedWithContent:(ContentType)content;
+ (instancetype)empty;
+ (instancetype)failedWithError:(nullable NSError *)error content:(nullable ContentType)content;

- (instancetype)init NS_UNAVAILABLE;

/// Same phase and error, new content. Used to turn models into display models.
- (MDBScreenState *)mapContent:(id _Nullable (^)(ContentType content))transform;

@property (nonatomic, readonly) BOOL isLoading;

@end

NS_ASSUME_NONNULL_END
