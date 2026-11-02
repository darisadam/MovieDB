//
//  MDBImageURLBuilder.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBImageSize) {
    MDBImageSizePosterSmall,   // w185, list thumbnails
    MDBImageSizePoster,        // w342, rows and grids
    MDBImageSizeBackdrop,      // w780, carousel and detail header
    MDBImageSizeProfile,       // w185, cast circles
    MDBImageSizeProfileLarge,  // h632, person header
};

@interface MDBImageURLBuilder : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (nullable NSURL *)URLForPath:(nullable NSString *)path size:(MDBImageSize)size;

@end

NS_ASSUME_NONNULL_END
