//
//  MDBLayoutFactory.h
//  MovieDB
//
//  Compositional layout sections shared by several screens.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MDBSectionHeaderKind;

@interface MDBLayoutFactory : NSObject

/// Full width paging carousel.
+ (NSCollectionLayoutSection *)carouselSectionWithHeight:(CGFloat)height;

/// Horizontal row of fixed size items with a header.
+ (NSCollectionLayoutSection *)horizontalRowSectionWithItemSize:(CGSize)itemSize
                                                        spacing:(CGFloat)spacing
                                                      hasHeader:(BOOL)hasHeader;

/// Three column poster grid with title and year under each poster.
+ (NSCollectionLayoutSection *)posterGridSectionWithEnvironment:(id<NSCollectionLayoutEnvironment>)environment
                                                      hasHeader:(BOOL)hasHeader;

/// One full width item, for headers like chips or counters inside a collection view.
+ (NSCollectionLayoutSection *)fullWidthSectionWithEstimatedHeight:(CGFloat)height;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
