//
//  MDBWindow.m
//  MovieDB
//

#import "MDBWindow.h"

NSNotificationName const MDBDebugShakeNotification = @"MDBDebugShakeNotification";

@implementation MDBWindow

- (void)motionEnded:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event {
#if DEBUG
    if (motion == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MDBDebugShakeNotification object:self];
        return;
    }
#endif
    [super motionEnded:motion withEvent:event];
}

@end
