//
//  MDBChipsRowCell.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A horizontally scrolling row of chips, used inside collection views.
@interface MDBChipsRowCell : UICollectionViewCell

@property (class, nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy, nullable) void (^onSelectIndex)(NSInteger index);

- (void)configureWithTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
