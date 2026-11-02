//
//  MDBStateView.h
//  MovieDB
//
//  Centered icon, title, message and an optional button. Used for empty, error and no results states.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBStateView : UIView

@property (nonatomic, copy, nullable) void (^onAction)(void);

- (void)configureWithSymbolName:(NSString *)symbolName
                          title:(NSString *)title
                        message:(nullable NSString *)message
                    actionTitle:(nullable NSString *)actionTitle
               actionSymbolName:(nullable NSString *)actionSymbolName;

/// Picks the icon and copy from an API error. Offers Retry unless the token is missing.
- (void)configureWithError:(NSError *)error;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
