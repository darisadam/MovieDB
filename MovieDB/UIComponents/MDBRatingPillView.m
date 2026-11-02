//
//  MDBRatingPillView.m
//  MovieDB
//

#import "MDBRatingPillView.h"
#import "MDBTheme.h"

@interface MDBRatingPillView ()
@property (nonatomic, readonly) UILabel *label;
@end

@implementation MDBRatingPillView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
        self.layer.cornerRadius = 4;
        self.isAccessibilityElement = NO;

        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:9 weight:UIImageSymbolWeightBold];
        UIImageView *star = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star.fill" withConfiguration:symbolConfig]];
        star.tintColor = UIColor.mdb_accent;
        star.translatesAutoresizingMaskIntoConstraints = NO;
        [star setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _label = [[UILabel alloc] init];
        _label.translatesAutoresizingMaskIntoConstraints = NO;
        _label.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        _label.textColor = UIColor.mdb_textPrimary;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[star, _label]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.spacing = 3;
        stack.alignment = UIStackViewAlignmentCenter;
        [self addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:5],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6],
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor constant:3],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-3],
        ]];
        self.hidden = YES;
    }
    return self;
}


- (void)setRatingText:(nullable NSString *)ratingText {
    BOOL hasRating = ratingText.length > 0 && ![ratingText isEqualToString:@"0.0"];
    self.label.text = hasRating ? ratingText : nil;
    self.hidden = !hasRating;
}

@end
