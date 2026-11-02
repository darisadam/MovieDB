//
//  MDBSectionHeaderView.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Section title on the left, optional "See All" on the right.
@interface MDBSectionHeaderView : UICollectionReusableView

@property (class, nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy, nullable) void (^onSeeAll)(void);

- (void)configureWithTitle:(NSString *)title showsSeeAll:(BOOL)showsSeeAll;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
