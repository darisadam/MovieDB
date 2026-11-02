//
//  MDBScreenState.m
//  MovieDB
//

#import "MDBScreenState.h"

@implementation MDBScreenState

- (instancetype)initWithPhase:(MDBLoadState)phase content:(nullable id)content error:(nullable NSError *)error {
  self = [super init];
  if (self) {
    _phase = phase;
    _content = content;
    _error = error;
  }
  return self;
}

+ (instancetype)idle {
  return [[self alloc] initWithPhase:MDBLoadStateIdle content:nil error:nil];
}

+ (instancetype)loadingWithContent:(nullable id)content {
  return [[self alloc] initWithPhase:MDBLoadStateLoading content:content error:nil];
}

+ (instancetype)loadedWithContent:(id)content {
  return [[self alloc] initWithPhase:MDBLoadStateLoaded content:content error:nil];
}

+ (instancetype)empty {
  return [[self alloc] initWithPhase:MDBLoadStateEmpty content:nil error:nil];
}

+ (instancetype)failedWithError:(nullable NSError *)error content:(nullable id)content {
  return [[self alloc] initWithPhase:MDBLoadStateFailed content:content error:error];
}

- (MDBScreenState *)mapContent:(id _Nullable (^)(id content))transform {
  id content = self.content;
  id mapped = content ? transform(content) : nil;
  return [[MDBScreenState alloc] initWithPhase:self.phase content:mapped error:self.error];
}

- (BOOL)isLoading {
  return self.phase == MDBLoadStateLoading;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<MDBScreenState %@ content=%@ error=%@>", MDBLoadStateName(self.phase),
                                    self.content ? @"yes" : @"no", self.error.localizedDescription ?: @"none"];
}

@end
