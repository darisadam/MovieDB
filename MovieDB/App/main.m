//
//  main.m
//  MovieDB
//

#import <UIKit/UIKit.h>
#import "MDBAppDelegate.h"

int main(int argc, char *argv[]) {
    NSString *appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([MDBAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
