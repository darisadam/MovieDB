//
//  MDBLayoutFactory.m
//  MovieDB
//

#import "MDBLayoutFactory.h"

NSString *const MDBSectionHeaderKind = @"MDBSectionHeaderKind";

static const CGFloat MDBHorizontalInset = 20;

@implementation MDBLayoutFactory

+ (NSCollectionLayoutBoundarySupplementaryItem *)headerItem {
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                  heightDimension:[NSCollectionLayoutDimension absoluteDimension:32]];
    return [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:size
                                                                                   elementKind:MDBSectionHeaderKind
                                                                                     alignment:NSRectAlignmentTop];
}

+ (NSCollectionLayoutSection *)carouselSectionWithHeight:(CGFloat)height {
    NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                      heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1]];
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
    NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                       heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorGroupPaging;
    section.contentInsets = NSDirectionalEdgeInsetsMake(0, 0, 24, 0);
    return section;
}

+ (NSCollectionLayoutSection *)horizontalRowSectionWithItemSize:(CGSize)itemSize spacing:(CGFloat)spacing hasHeader:(BOOL)hasHeader {
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:itemSize.width]
                                                                  heightDimension:[NSCollectionLayoutDimension absoluteDimension:itemSize.height]];
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:size];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:size subitems:@[item]];
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.orthogonalScrollingBehavior = UICollectionLayoutSectionOrthogonalScrollingBehaviorContinuous;
    section.interGroupSpacing = spacing;
    section.contentInsets = NSDirectionalEdgeInsetsMake(8, MDBHorizontalInset, 28, MDBHorizontalInset);
    if (hasHeader) {
        section.boundarySupplementaryItems = @[[self headerItem]];
    }
    return section;
}

+ (NSCollectionLayoutSection *)posterGridSectionWithEnvironment:(id<NSCollectionLayoutEnvironment>)environment hasHeader:(BOOL)hasHeader {
    CGFloat spacing = 10;
    CGFloat columns = environment.container.effectiveContentSize.width > 600 ? 5 : 3;
    CGFloat available = environment.container.effectiveContentSize.width - MDBHorizontalInset * 2 - spacing * (columns - 1);
    CGFloat width = floor(available / columns);
    // Poster is 2:3, plus room for the title and the year below it.
    CGFloat height = ceil(width * 1.5) + 44;

    NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                                                      heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]];
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
    NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                       heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitem:item count:(NSInteger)columns];
    group.interItemSpacing = [NSCollectionLayoutSpacing fixedSpacing:spacing];
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.interGroupSpacing = 16;
    section.contentInsets = NSDirectionalEdgeInsetsMake(8, MDBHorizontalInset, 24, MDBHorizontalInset);
    if (hasHeader) {
        section.boundarySupplementaryItems = @[[self headerItem]];
    }
    return section;
}

+ (NSCollectionLayoutSection *)fullWidthSectionWithEstimatedHeight:(CGFloat)height {
    NSCollectionLayoutSize *size = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                                                  heightDimension:[NSCollectionLayoutDimension estimatedDimension:height]];
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:size];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:size subitems:@[item]];
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    section.contentInsets = NSDirectionalEdgeInsetsMake(12, 0, 4, 0);
    return section;
}

@end
