//
//  MDBLoadState.m
//  MovieDB
//

#import "MDBLoadState.h"

NSString *MDBLoadStateName(MDBLoadState state) {
  switch (state) {
    case MDBLoadStateIdle: return @"idle";
    case MDBLoadStateLoading: return @"loading";
    case MDBLoadStateLoaded: return @"loaded";
    case MDBLoadStateEmpty: return @"empty";
    case MDBLoadStateFailed: return @"failed";
  }
  return @"unknown";
}
