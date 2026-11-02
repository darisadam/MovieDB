//
//  MDBMacros.h
//  MovieDB
//

#import <Foundation/Foundation.h>

// Main thread check for code that touches UI state. Compiled out in Release by NS_BLOCK_ASSERTIONS.
#define MDBAssertMainThread() NSCAssert([NSThread isMainThread], @"Expected to run on the main thread")

NS_INLINE BOOL MDBIsRunningUnitTests(void) {
    return NSClassFromString(@"XCTestCase") != nil;
}
