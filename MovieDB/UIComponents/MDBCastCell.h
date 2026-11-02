//
//  MDBCastCell.h
//  MovieDB
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDBCastCellModel : NSObject

@property (nonatomic, readonly) NSInteger personID;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *character;
@property (nonatomic, copy, readonly, nullable) NSURL *photoURL;

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                       character:(nullable NSString *)character
                        photoURL:(nullable NSURL *)photoURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

@interface MDBCastCell : UICollectionViewCell

@property (class, nonatomic, readonly) NSString *identifier;

- (void)configureWithModel:(MDBCastCellModel *)model;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
