//
//  MDBCoordinator.h
//  MovieDB
//
//  Coordinators own navigation. View controllers only report what the user did
//  through their delegate, and the coordinator decides what screen comes next.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MDBCoordinator <NSObject>
- (void)start;
@end

@interface MDBBaseCoordinator : NSObject <MDBCoordinator>

/// Weak so a child never keeps its parent alive.
@property (nonatomic, weak, nullable) MDBBaseCoordinator *parentCoordinator;
@property (nonatomic, copy, readonly) NSArray<MDBBaseCoordinator *> *childCoordinators;

/// Subclasses override. The base version only logs.
- (void)start;

- (void)addChildCoordinator:(MDBBaseCoordinator *)child;
- (void)removeChildCoordinator:(MDBBaseCoordinator *)child;

/// Indented tree of this coordinator and its children, used by the debug tools.
- (NSString *)treeDescription;

@end

NS_ASSUME_NONNULL_END
