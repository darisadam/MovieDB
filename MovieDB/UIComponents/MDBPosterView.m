//
//  MDBPosterView.m
//  MovieDB
//

#import "MDBPosterView.h"
#import "MDBRatingPillView.h"
#import "MDBTheme.h"
#import <SDWebImage/SDWebImage.h>

@interface MDBPosterView ()
@property (nonatomic, readonly) MDBRatingPillView *ratingPill;
@property (nonatomic, readonly) UIImageView *placeholderView;
@end

@implementation MDBPosterView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = UIColor.mdb_surfaceRaised;
        self.layer.cornerRadius = 6;
        self.layer.cornerCurve = kCACornerCurveContinuous;
        self.clipsToBounds = YES;
        _showsRating = YES;

        UIImageSymbolConfiguration *symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
        _placeholderView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"film" withConfiguration:symbolConfig]];
        _placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
        _placeholderView.tintColor = [UIColor colorWithWhite:1 alpha:0.2];
        [self addSubview:_placeholderView];

        _imageView = [[UIImageView alloc] init];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.sd_imageTransition = SDWebImageTransition.fadeTransition;
        [self addSubview:_imageView];

        _ratingPill = [[MDBRatingPillView alloc] initWithFrame:CGRectZero];
        [self addSubview:_ratingPill];

        [NSLayoutConstraint activateConstraints:@[
            [_placeholderView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_placeholderView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_imageView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_ratingPill.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:6],
            [_ratingPill.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        ]];
    }
    return self;
}


- (void)setImageURL:(nullable NSURL *)imageURL {
    if (!imageURL) {
        [self.imageView sd_cancelCurrentImageLoad];
        self.imageView.image = nil;
        return;
    }
    [self.imageView sd_setImageWithURL:imageURL
                      placeholderImage:nil
                               options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages];
}

- (void)setRatingText:(nullable NSString *)ratingText {
    [self.ratingPill setRatingText:self.showsRating ? ratingText : nil];
}

- (void)setShowsRating:(BOOL)showsRating {
    _showsRating = showsRating;
    if (!showsRating) {
        [self.ratingPill setRatingText:nil];
    }
}

- (void)reset {
    [self.imageView sd_cancelCurrentImageLoad];
    self.imageView.image = nil;
    [self.ratingPill setRatingText:nil];
}

@end
