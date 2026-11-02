//
//  MDBButtonFactory.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBButtonStyle) {
    MDBButtonStylePrimary,    // yellow fill, dark text
    MDBButtonStyleSecondary,  // outline, white text, yellow icon
    MDBButtonStyleFavorited,  // tinted yellow, used when a movie is saved
};

@interface MDBButtonFactory : NSObject

+ (UIButtonConfiguration *)configurationWithStyle:(MDBButtonStyle)style
                                            title:(NSString *)title
                                       symbolName:(nullable NSString *)symbolName;

+ (UIButton *)buttonWithStyle:(MDBButtonStyle)style title:(NSString *)title symbolName:(nullable NSString *)symbolName;

/// A pill shaped chip. Selected chips are filled with the accent color.
+ (UIButton *)chipWithTitle:(NSString *)title;
+ (void)setChip:(UIButton *)chip selected:(BOOL)selected;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
