//
//  MDBCastCell.m
//  MovieDB
//

#import "MDBCastCell.h"
#import <SDWebImage/SDWebImage.h>
#import "MDBTheme.h"

@implementation MDBCastCellModel

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                       character:(nullable NSString *)character
                        photoURL:(nullable NSURL *)photoURL {
  self = [super init];
  if (self) {
    _personID = personID;
    _name = [name copy];
    _character = [character copy] ?: @"";
    _photoURL = [photoURL copy];
  }
  return self;
}

@end

@interface MDBCastCell ()
@property (nonatomic, readonly) UIImageView *photoView;
@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *characterLabel;
@end

@implementation MDBCastCell

+ (NSString *)identifier {
  return @"MDBCastCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _photoView = [[UIImageView alloc] init];
    _photoView.translatesAutoresizingMaskIntoConstraints = NO;
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    _photoView.clipsToBounds = YES;
    _photoView.layer.cornerRadius = 36;
    _photoView.backgroundColor = UIColor.mdb_surfaceRaised;
    _photoView.tintColor = [UIColor colorWithWhite:1 alpha:0.25];
    _photoView.sd_imageTransition = SDWebImageTransition.fadeTransition;

    _nameLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightMedium textStyle:UIFontTextStyleCaption1
                                   color:UIColor.mdb_textPrimary];
    _nameLabel.numberOfLines = 2;
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _characterLabel = [MDBTheme labelWithSize:11 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption2
                                        color:UIColor.mdb_textSecondary];
    _characterLabel.textAlignment = NSTextAlignmentCenter;

    [self.contentView addSubview:_photoView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_characterLabel];
    [NSLayoutConstraint activateConstraints:@[
      [_photoView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [_photoView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
      [_photoView.widthAnchor constraintEqualToConstant:72],
      [_photoView.heightAnchor constraintEqualToConstant:72],
      [_nameLabel.topAnchor constraintEqualToAnchor:_photoView.bottomAnchor constant:8],
      [_nameLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
      [_nameLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
      [_characterLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:2],
      [_characterLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
      [_characterLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
    ]];

    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
  }
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  [self.photoView sd_cancelCurrentImageLoad];
  self.photoView.image = nil;
}

- (void)configureWithModel:(MDBCastCellModel *)model {
  UIImage *placeholder = [UIImage systemImageNamed:@"person.fill"];
  [self.photoView sd_setImageWithURL:model.photoURL placeholderImage:placeholder options:SDWebImageRetryFailed];
  self.nameLabel.text = model.name;
  self.characterLabel.text = model.character;
  self.accessibilityLabel =
      model.character.length > 0 ? [NSString stringWithFormat:@"%@ as %@", model.name, model.character] : model.name;
}

@end
