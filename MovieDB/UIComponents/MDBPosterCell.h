//
//  MDBPosterCell.h
//  MovieDB
//

#import <UIKit/UIKit.h>

@class MDBMovieCellModel;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MDBPosterCellStyle) {
    MDBPosterCellStylePlain,   // poster only, Home rows
    MDBPosterCellStyleTitled,  // poster, title and year, grids
    MDBPosterCellStyleDated,   // poster and release date, Upcoming row
};

@interface MDBPosterCell : UICollectionViewCell

@property (class, nonatomic, readonly) NSString *identifier;

- (void)configureWithModel:(MDBMovieCellModel *)model style:(MDBPosterCellStyle)style;

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
