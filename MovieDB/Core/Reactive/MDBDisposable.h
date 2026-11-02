//
//  MDBDisposable.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Something that can be stopped, usually a subscription.
@protocol MDBDisposable <NSObject>
- (void)dispose;
@end

/// Runs a block once on dispose. Disposing twice is a no-op.
@interface MDBBlockDisposable : NSObject <MDBDisposable>

+ (instancetype)disposableWithBlock:(dispatch_block_t)block;
- (instancetype)init NS_UNAVAILABLE;

@end

/// Holds subscriptions and disposes all of them when it is deallocated.
/// Give each view controller or view model one and its subscriptions end with it.
@interface MDBDisposeBag : NSObject

- (void)addDisposable:(id<MDBDisposable>)disposable;
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
