//
//  MDBStateView.m
//  MovieDB
//

#import "MDBStateView.h"
#import "MDBAPIError.h"
#import "MDBButtonFactory.h"
#import "MDBTheme.h"

@interface MDBStateView ()
@property (nonatomic, readonly) UIImageView *iconView;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *messageLabel;
@property (nonatomic, readonly) UIButton *actionButton;
@end

@implementation MDBStateView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        UIView *circle = [[UIView alloc] init];
        circle.translatesAutoresizingMaskIntoConstraints = NO;
        circle.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
        circle.layer.cornerRadius = 44;

        _iconView = [[UIImageView alloc] init];
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        _iconView.tintColor = UIColor.mdb_accent;
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.preferredSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:34 weight:UIImageSymbolWeightRegular];
        [circle addSubview:_iconView];

        _titleLabel = [MDBTheme labelWithSize:18 weight:UIFontWeightSemibold textStyle:UIFontTextStyleHeadline color:UIColor.mdb_textPrimary];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;

        _messageLabel = [MDBTheme labelWithSize:14 weight:UIFontWeightRegular textStyle:UIFontTextStyleSubheadline color:UIColor.mdb_textSecondary];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;

        _actionButton = [MDBButtonFactory buttonWithStyle:MDBButtonStylePrimary title:@"Try Again" symbolName:nil];
        [_actionButton addTarget:self action:@selector(actionTapped) forControlEvents:UIControlEventTouchUpInside];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[circle, _titleLabel, _messageLabel, _actionButton]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 12;
        [stack setCustomSpacing:20 afterView:circle];
        [stack setCustomSpacing:24 afterView:_messageLabel];
        [self addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
            [circle.widthAnchor constraintEqualToConstant:88],
            [circle.heightAnchor constraintEqualToConstant:88],
            [_iconView.centerXAnchor constraintEqualToAnchor:circle.centerXAnchor],
            [_iconView.centerYAnchor constraintEqualToAnchor:circle.centerYAnchor],
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:40],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-40],
            [stack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-20],
            [stack.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor constant:16],
            [_titleLabel.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
            [_messageLabel.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        ]];
    }
    return self;
}


- (void)configureWithSymbolName:(NSString *)symbolName
                          title:(NSString *)title
                        message:(nullable NSString *)message
                    actionTitle:(nullable NSString *)actionTitle
               actionSymbolName:(nullable NSString *)actionSymbolName {
    self.iconView.image = [UIImage systemImageNamed:symbolName];
    self.titleLabel.text = title;
    self.messageLabel.text = message;
    self.messageLabel.hidden = message.length == 0;
    NSString *buttonTitle = actionTitle;
    if (buttonTitle.length > 0) {
        self.actionButton.configuration = [MDBButtonFactory configurationWithStyle:MDBButtonStylePrimary
                                                                             title:buttonTitle
                                                                        symbolName:actionSymbolName];
        self.actionButton.hidden = NO;
    } else {
        self.actionButton.hidden = YES;
    }
    self.accessibilityElements = @[self.titleLabel, self.messageLabel, self.actionButton];
}

- (void)configureWithError:(NSError *)error {
    NSString *symbol = @"exclamationmark.triangle";
    NSString *actionTitle = @"Try Again";
    if (error.mdb_isOffline) {
        symbol = @"wifi.slash";
    } else if (error.mdb_isMissingToken) {
        symbol = @"key";
        actionTitle = nil;
    } else if ([error.domain isEqualToString:MDBAPIErrorDomain] && error.code == MDBAPIErrorUnauthorized) {
        symbol = @"lock";
    }
    [self configureWithSymbolName:symbol
                            title:error.mdb_userFacingTitle
                          message:error.mdb_userFacingMessage
                      actionTitle:actionTitle
                 actionSymbolName:actionTitle ? @"arrow.clockwise" : nil];
}

- (void)actionTapped {
    if (self.onAction) {
        self.onAction();
    }
}

@end
