//
//  MDBObservable.m
//  MovieDB
//

#import "MDBObservable.h"

typedef void (^MDBObserverBlock)(id _Nullable value);

@interface MDBObservable ()
@property (nonatomic, readwrite, nullable) id value;
@property (nonatomic, readwrite) BOOL hasValue;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, MDBObserverBlock> *observers;
@property (nonatomic) NSUInteger nextToken;
/// Keeps an upstream subscription alive for derived streams.
@property (nonatomic, nullable) id<MDBDisposable> upstream;
@end

@implementation MDBObservable

- (instancetype)init {
  self = [super init];
  if (self) {
    _observers = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)dealloc {
  [_upstream dispose];
}

#pragma mark - Emitting

- (void)emit:(nullable id)value {
  NSArray<MDBObserverBlock> *observers = nil;
  @synchronized(self) {
    self.value = value;
    self.hasValue = YES;
    observers = [self.observers.allValues copy];
  }
  for (MDBObserverBlock observer in observers) {
    observer(value);
  }
}

#pragma mark - Subscribing

- (id<MDBDisposable>)subscribe:(void (^)(id _Nullable value))observer {
  MDBObserverBlock block = [observer copy];
  NSNumber *token = nil;
  BOOL replay = NO;
  id current = nil;
  @synchronized(self) {
    token = @(self.nextToken++);
    self.observers[token] = block;
    replay = self.hasValue;
    current = self.value;
  }
  if (replay) {
    block(current);
  }
  // The disposable holds the observable strongly, so a derived stream lives as long as someone listens.
  MDBObservable *observable = self;
  return [MDBBlockDisposable disposableWithBlock:^{
    @synchronized(observable) {
      [observable.observers removeObjectForKey:token];
    }
  }];
}

#pragma mark - Operators

/// A new stream fed by this one. The source holds the derived stream weakly, the
/// derived stream holds the subscription to its source, so there is no cycle.
- (MDBObservable *)derivedWithHandler:(void (^)(MDBObservable *derived, id _Nullable value))handler {
  MDBObservable *derived = [[MDBObservable alloc] init];
  __weak MDBObservable *weakDerived = derived;
  derived.upstream = [self subscribe:^(id _Nullable value) {
    MDBObservable *strongDerived = weakDerived;
    if (strongDerived) {
      handler(strongDerived, value);
    }
  }];
  return derived;
}

- (MDBObservable *)map:(id _Nullable (^)(id _Nullable value))transform {
  return [self derivedWithHandler:^(MDBObservable *derived, id _Nullable value) {
    [derived emit:transform(value)];
  }];
}

- (MDBObservable *)filter:(BOOL (^)(id _Nullable value))predicate {
  return [self derivedWithHandler:^(MDBObservable *derived, id _Nullable value) {
    if (predicate(value)) {
      [derived emit:value];
    }
  }];
}

- (MDBObservable *)distinctUntilChanged {
  return [self derivedWithHandler:^(MDBObservable *derived, id _Nullable value) {
    BOOL same = derived.hasValue && (derived.value == value || [derived.value isEqual:value]);
    if (!same) {
      [derived emit:value];
    }
  }];
}

- (MDBObservable *)skip:(NSUInteger)count {
  __block NSUInteger remaining = count;
  return [self derivedWithHandler:^(MDBObservable *derived, id _Nullable value) {
    if (remaining > 0) {
      remaining -= 1;
      return;
    }
    [derived emit:value];
  }];
}

- (MDBObservable *)debounce:(NSTimeInterval)interval {
  __block NSUInteger generation = 0;
  return [self derivedWithHandler:^(MDBObservable *derived, id _Nullable value) {
    generation += 1;
    NSUInteger scheduled = generation;
    __weak MDBObservable *weakDerived = derived;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      // A newer value arrived while we were waiting, so this one is stale.
      if (scheduled == generation) {
        [weakDerived emit:value];
      }
    });
  }];
}

+ (MDBObservable *)combineLatest:(MDBObservable *)first
                            with:(MDBObservable *)second
                          reduce:(id _Nullable (^)(id _Nullable, id _Nullable))reduce {
  MDBObservable *combined = [[MDBObservable alloc] init];
  __weak MDBObservable *weakCombined = combined;
  __weak MDBObservable *weakFirst = first;
  __weak MDBObservable *weakSecond = second;
  void (^update)(void) = ^{
    MDBObservable *strongFirst = weakFirst;
    MDBObservable *strongSecond = weakSecond;
    if (strongFirst.hasValue && strongSecond.hasValue) {
      [weakCombined emit:reduce(strongFirst.value, strongSecond.value)];
    }
  };
  id<MDBDisposable> firstSubscription = [first subscribe:^(id _Nullable value) {
    update();
  }];
  id<MDBDisposable> secondSubscription = [second subscribe:^(id _Nullable value) {
    update();
  }];
  combined.upstream = [MDBBlockDisposable disposableWithBlock:^{
    [firstSubscription dispose];
    [secondSubscription dispose];
  }];
  return combined;
}

@end

@implementation MDBSubject

- (instancetype)init {
  return [super init];
}

- (instancetype)initWithValue:(nullable id)value {
  self = [super init];
  if (self) {
    self.value = value;
    self.hasValue = YES;
  }
  return self;
}

- (void)send:(nullable id)value {
  [self emit:value];
}

@end
