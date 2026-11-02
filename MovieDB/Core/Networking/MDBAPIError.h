//
//  MDBAPIError.h
//  MovieDB
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const MDBAPIErrorDomain;
/// NSNumber with the HTTP status code, when there was a response.
FOUNDATION_EXPORT NSString *const MDBAPIErrorStatusCodeKey;

typedef NS_ERROR_ENUM(MDBAPIErrorDomain, MDBAPIErrorCode) {
    MDBAPIErrorMissingToken = 1,
    MDBAPIErrorInvalidRequest,
    MDBAPIErrorOffline,
    MDBAPIErrorTransport,
    MDBAPIErrorUnauthorized,
    MDBAPIErrorNotFound,
    MDBAPIErrorHTTPStatus,
    MDBAPIErrorDecoding,
    MDBAPIErrorCancelled,
};

@interface NSError (MDBAPIError)

+ (instancetype)mdb_apiErrorWithCode:(MDBAPIErrorCode)code
                             message:(nullable NSString *)message
                          underlying:(nullable NSError *)underlying;
/// Maps NSURLErrorDomain errors to our codes, so offline and cancelled are easy to check.
+ (instancetype)mdb_apiErrorFromTransportError:(NSError *)error;
+ (instancetype)mdb_apiErrorWithStatusCode:(NSInteger)statusCode message:(nullable NSString *)message;

@property (nonatomic, readonly) BOOL mdb_isOffline;
@property (nonatomic, readonly) BOOL mdb_isCancelled;
@property (nonatomic, readonly) BOOL mdb_isMissingToken;

/// Short title and message for the error state view.
@property (nonatomic, readonly) NSString *mdb_userFacingTitle;
@property (nonatomic, readonly) NSString *mdb_userFacingMessage;

@end

NS_ASSUME_NONNULL_END
