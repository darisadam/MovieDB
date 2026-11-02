//
//  MDBDisposable.m
//  MovieDB
//

#import "MDBDisposable.h"

@interface MDBBlockDisposable ()
@property (nonatomic, copy, nullable) dispatch_block_t block;
@end

@implementation MDBBlockDisposable

+ (instancetype)disposableWithBlock:(dispatch_block_t)block {
  MDBBlockDisposable *disposable = [[self alloc] initPrivate];
  disposable.block = block;
  return disposable;
}

- (instancetype)initPrivate {
  return [super init];
}

- (void)dispose {
  dispatch_block_t block = nil;
  @synchronized(self) {
    block = self.block;
    self.block = nil;
  }
  if (block) {
    block();
  }
}

@end

@interface MDBDisposeBag ()
@property (nonatomic, readonly) NSMutableArray<id<MDBDisposable>> *disposables;
@end

@implementation MDBDisposeBag

- (instancetype)init {
  self = [super init];
  if (self) {
    _disposables = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc {
  for (id<MDBDisposable> disposable in _disposables) {
    [disposable dispose];
  }
}

- (void)addDisposable:(id<MDBDisposable>)disposable {
  @synchronized(self) {
    [self.disposables addObject:disposable];
  }
}

- (void)dispose {
  NSArray<id<MDBDisposable>> *snapshot = nil;
  @synchronized(self) {
    snapshot = [self.disposables copy];
    [self.disposables removeAllObjects];
  }
  for (id<MDBDisposable> disposable in snapshot) {
    [disposable dispose];
  }
}

@end
