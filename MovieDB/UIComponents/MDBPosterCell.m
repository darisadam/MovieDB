//
//  MDBPosterCell.m
//  MovieDB
//

#import "MDBPosterCell.h"
#import "MDBMovieCellModel.h"
#import "MDBPosterView.h"
#import "MDBTheme.h"

@interface MDBPosterCell ()
@property (nonatomic, readonly) MDBPosterView *posterView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *subtitleLabel;
@end

@implementation MDBPosterCell

+ (NSString *)identifier {
    return @"MDBPosterCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _posterView = [[MDBPosterView alloc] initWithFrame:CGRectZero];
        _titleLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightMedium textStyle:UIFontTextStyleCaption1 color:UIColor.mdb_textPrimary];
        _titleLabel.numberOfLines = 1;
        _subtitleLabel = [MDBTheme labelWithSize:11 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption2 color:UIColor.mdb_textSecondary];

        [self.contentView addSubview:_posterView];
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_subtitleLabel];

        NSLayoutConstraint *ratio = [_posterView.heightAnchor constraintEqualToAnchor:_posterView.widthAnchor multiplier:1.5];
        ratio.priority = UILayoutPriorityRequired - 1;
        [NSLayoutConstraint activateConstraints:@[
            [_posterView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_posterView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_posterView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            ratio,
            [_titleLabel.topAnchor constraintEqualToAnchor:_posterView.bottomAnchor constant:6],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:2],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_subtitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        ]];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    [self.posterView reset];
    self.titleLabel.text = nil;
    self.subtitleLabel.text = nil;
}

- (void)configureWithModel:(MDBMovieCellModel *)model style:(MDBPosterCellStyle)style {
    [self.posterView setImageURL:model.posterURL];
    self.posterView.showsRating = style != MDBPosterCellStyleDated;
    [self.posterView setRatingText:model.rating > 0 ? model.ratingText : nil];

    switch (style) {
        case MDBPosterCellStylePlain:
            self.titleLabel.hidden = YES;
            self.subtitleLabel.hidden = YES;
            break;
        case MDBPosterCellStyleTitled:
            self.titleLabel.hidden = NO;
            self.subtitleLabel.hidden = NO;
            self.titleLabel.text = model.title;
            self.subtitleLabel.text = model.yearText;
            break;
        case MDBPosterCellStyleDated:
            self.titleLabel.hidden = YES;
            self.subtitleLabel.hidden = NO;
            self.titleLabel.text = @" ";
            self.subtitleLabel.text = model.releaseDateText;
            break;
    }
    self.accessibilityLabel = model.accessibilityLabelText;
    self.accessibilityValue = style == MDBPosterCellStyleDated ? [NSString stringWithFormat:@"Releases %@", model.releaseDateText] : nil;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.15 animations:^{
        self.contentView.transform = highlighted ? CGAffineTransformMakeScale(0.96, 0.96) : CGAffineTransformIdentity;
    }];
}

@end
