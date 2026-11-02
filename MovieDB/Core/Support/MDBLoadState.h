//
//  MDBLoadState.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBLoadState) {
    MDBLoadStateIdle = 0,
    MDBLoadStateLoading,
    MDBLoadStateLoaded,
    MDBLoadStateEmpty,
    MDBLoadStateFailed,
};

FOUNDATION_EXPORT NSString *MDBLoadStateName(MDBLoadState state);

NS_ASSUME_NONNULL_END
