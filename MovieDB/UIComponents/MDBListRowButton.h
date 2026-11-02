//
//  MDBListRowButton.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A settings style row: icon, title, value and a chevron, with a hairline under it.
/// It is a UIButton so it can show a UIMenu on tap.
@interface MDBListRowButton : UIButton

+ (instancetype)rowWithSymbolName:(NSString *)symbolName title:(NSString *)title;

@property (nonatomic, copy, nullable) NSString *valueText;
@property (nonatomic) BOOL showsChevron;
@property (nonatomic) BOOL destructive;

@end

NS_ASSUME_NONNULL_END
