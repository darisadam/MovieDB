//
//  MDBCarouselCell.m
//  MovieDB
//

#import "MDBCarouselCell.h"
#import "MDBMovieCellModel.h"
#import "MDBRatingPillView.h"
#import "MDBTheme.h"
#import <SDWebImage/SDWebImage.h>

@interface MDBCarouselCell ()
@property (nonatomic, readonly) UIImageView *backdropView;
@property (nonatomic, readonly) CAGradientLayer *scrim;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *metaLabel;
@property (nonatomic, readonly) MDBRatingPillView *ratingPill;
@property (nonatomic, readonly) UIStackView *dotsStack;
@end

@implementation MDBCarouselCell

+ (NSString *)identifier {
    return @"MDBCarouselCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.mdb_surfaceRaised;
        self.contentView.clipsToBounds = YES;

        _backdropView = [[UIImageView alloc] init];
        _backdropView.translatesAutoresizingMaskIntoConstraints = NO;
        _backdropView.contentMode = UIViewContentModeScaleAspectFill;
        _backdropView.clipsToBounds = YES;
        _backdropView.sd_imageTransition = SDWebImageTransition.fadeTransition;
        [self.contentView addSubview:_backdropView];

        _scrim = [CAGradientLayer layer];
        UIColor *background = UIColor.mdb_background;
        _scrim.colors = @[
            (id)[background colorWithAlphaComponent:0].CGColor,
            (id)[background colorWithAlphaComponent:0.85].CGColor,
            (id)background.CGColor,
        ];
        _scrim.locations = @[@0.15, @0.7, @1.0];
        [self.contentView.layer addSublayer:_scrim];

        UILabel *eyebrow = [MDBTheme labelWithSize:11 weight:UIFontWeightSemibold textStyle:UIFontTextStyleCaption2 color:UIColor.mdb_accent];
        eyebrow.text = @"NOW PLAYING";

        _titleLabel = [MDBTheme labelWithSize:22 weight:UIFontWeightBold textStyle:UIFontTextStyleTitle2 color:UIColor.mdb_textPrimary];
        _titleLabel.numberOfLines = 2;

        _ratingPill = [[MDBRatingPillView alloc] initWithFrame:CGRectZero];
        _metaLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1 color:[UIColor colorWithWhite:1 alpha:0.75]];

        UIStackView *metaRow = [[UIStackView alloc] initWithArrangedSubviews:@[_ratingPill, _metaLabel]];
        metaRow.spacing = 8;
        metaRow.alignment = UIStackViewAlignmentCenter;

        UIStackView *info = [[UIStackView alloc] initWithArrangedSubviews:@[eyebrow, _titleLabel, metaRow]];
        info.translatesAutoresizingMaskIntoConstraints = NO;
        info.axis = UILayoutConstraintAxisVertical;
        info.alignment = UIStackViewAlignmentLeading;
        info.spacing = 6;
        [self.contentView addSubview:info];

        _dotsStack = [[UIStackView alloc] init];
        _dotsStack.translatesAutoresizingMaskIntoConstraints = NO;
        _dotsStack.spacing = 4;
        _dotsStack.alignment = UIStackViewAlignmentCenter;
        [self.contentView addSubview:_dotsStack];

        [NSLayoutConstraint activateConstraints:@[
            [_backdropView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_backdropView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_backdropView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_backdropView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [info.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [info.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [info.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-26],
            [_dotsStack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [_dotsStack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],
            [_dotsStack.heightAnchor constraintEqualToConstant:5],
        ]];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.scrim.frame = self.contentView.bounds;
    [CATransaction commit];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.backdropView sd_cancelCurrentImageLoad];
    self.backdropView.image = nil;
}

- (void)configureWithModel:(MDBMovieCellModel *)model pageIndex:(NSInteger)pageIndex pageCount:(NSInteger)pageCount {
    [self.backdropView sd_setImageWithURL:model.backdropURL ?: model.posterURL placeholderImage:nil options:SDWebImageRetryFailed];
    self.titleLabel.text = model.title;
    self.metaLabel.text = model.metaText;
    [self.ratingPill setRatingText:model.rating > 0 ? model.ratingText : nil];
    [self updateDotsWithIndex:pageIndex count:pageCount];

    self.accessibilityLabel = [NSString stringWithFormat:@"Now playing, %@", model.accessibilityLabelText];
    self.accessibilityValue = [NSString stringWithFormat:@"%ld of %ld", (long)pageIndex + 1, (long)pageCount];
}

- (void)updateDotsWithIndex:(NSInteger)index count:(NSInteger)count {
    for (UIView *dot in self.dotsStack.arrangedSubviews) {
        [dot removeFromSuperview];
    }
    for (NSInteger dotIndex = 0; dotIndex < count; dotIndex++) {
        BOOL isCurrent = dotIndex == index;
        UIView *dot = [[UIView alloc] init];
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        dot.backgroundColor = isCurrent ? UIColor.mdb_accent : [UIColor colorWithWhite:1 alpha:0.4];
        dot.layer.cornerRadius = 2.5;
        [NSLayoutConstraint activateConstraints:@[
            [dot.widthAnchor constraintEqualToConstant:isCurrent ? 18 : 5],
            [dot.heightAnchor constraintEqualToConstant:5],
        ]];
        [self.dotsStack addArrangedSubview:dot];
    }
}

@end
