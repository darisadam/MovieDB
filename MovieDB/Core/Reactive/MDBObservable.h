//
//  MDBObservable.h
//  MovieDB
//
//  A small value stream, enough for view models to publish state and for view
//  controllers to bind to it. It always holds the latest value and replays it to
//  new subscribers, like a BehaviorSubject.
//
//  Values arrive on the thread they were sent from. In this app that is always main.
//

#import <Foundation/Foundation.h>
#import "MDBDisposable.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDBObservable<__covariant ObjectType> : NSObject

/// The latest value, or nil before the first one.
@property (nonatomic, readonly, nullable) ObjectType value;
@property (nonatomic, readonly) BOOL hasValue;

/// Calls the observer with the current value right away (if there is one) and on every change.
/// Keep the returned disposable, usually in an MDBDisposeBag. Dropping it does not cancel.
- (id<MDBDisposable>)subscribe:(void (^)(ObjectType _Nullable value))observer;

/// Derived streams. They keep their source alive while they are subscribed.
- (MDBObservable *)map:(id _Nullable (^)(ObjectType _Nullable value))transform;
- (MDBObservable<ObjectType> *)filter:(BOOL (^)(ObjectType _Nullable value))predicate;
/// Drops values equal (isEqual:) to the previous one.
- (MDBObservable<ObjectType> *)distinctUntilChanged;
/// Ignores the first count values, handy to skip the replayed current value.
- (MDBObservable<ObjectType> *)skip:(NSUInteger)count;
/// Emits only after the source stayed quiet for the interval. Delivers on the main queue.
- (MDBObservable<ObjectType> *)debounce:(NSTimeInterval)interval;

/// Emits reduce(a, b) whenever either side changes, once both have a value.
+ (MDBObservable *)combineLatest:(MDBObservable *)first
                            with:(MDBObservable *)second
                          reduce:(id _Nullable (^)(id _Nullable first, id _Nullable second))reduce;

@end

/// An observable you can push values into. View models keep these private and
/// expose them typed as MDBObservable.
@interface MDBSubject<ObjectType> : MDBObservable <ObjectType>

/// A subject with no value yet. Subscribers get called on the first send.
- (instancetype)init;
- (instancetype)initWithValue:(nullable ObjectType)value;

- (void)send:(nullable ObjectType)value;

@end

NS_ASSUME_NONNULL_END
