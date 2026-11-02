//
//  MDBCoordinator.m
//  MovieDB
//

#import "MDBCoordinator.h"
#import "MDBLog.h"

@interface MDBBaseCoordinator ()
@property (nonatomic, readonly) NSMutableArray<MDBBaseCoordinator *> *children;
@end

@implementation MDBBaseCoordinator

- (instancetype)init {
  self = [super init];
  if (self) {
    _children = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc {
  MDBLogDebug(MDBLogCategoryCoordinator, @"%@ deallocated", NSStringFromClass([self class]));
}

- (NSArray<MDBBaseCoordinator *> *)childCoordinators {
  return [self.children copy];
}

- (void)start {
  MDBLogDebug(MDBLogCategoryCoordinator, @"%@ started", NSStringFromClass([self class]));
}

- (void)addChildCoordinator:(MDBBaseCoordinator *)child {
  if ([self.children containsObject:child]) {
    return;
  }
  child.parentCoordinator = self;
  [self.children addObject:child];
}

- (void)removeChildCoordinator:(MDBBaseCoordinator *)child {
  child.parentCoordinator = nil;
  [self.children removeObject:child];
}

- (NSString *)treeDescription {
  NSMutableString *output = [NSMutableString string];
  [self appendTreeTo:output depth:0];
  return [output copy];
}

- (void)appendTreeTo:(NSMutableString *)output depth:(NSUInteger)depth {
  NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
  [output appendFormat:@"%@%@ %p\n", indent, NSStringFromClass([self class]), self];
  for (MDBBaseCoordinator *child in self.children) {
    [child appendTreeTo:output depth:depth + 1];
  }
}

@end
