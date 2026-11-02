//
//  MDBAboutViewController.m
//  MovieDB
//

#import "MDBAboutViewController.h"
#import "MDBListRowButton.h"
#import "MDBTheme.h"

static NSString *const MDBTMDBURL = @"https://www.themoviedb.org";
static NSString *const MDBRepositoryURL = @"https://github.com/darisadam/MovieDB";
static NSString *const MDBAttributionURL = @"https://www.themoviedb.org/about/logos-attribution";

@implementation MDBAboutViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"About";
  self.view.backgroundColor = UIColor.mdb_background;
  self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

  UIScrollView *scrollView = [[UIScrollView alloc] init];
  scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  scrollView.alwaysBounceVertical = YES;
  [self.view addSubview:scrollView];

  UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
  logo.contentMode = UIViewContentModeScaleAspectFit;
  logo.isAccessibilityElement = YES;
  logo.accessibilityLabel = @"MovieDB";
  [logo.heightAnchor constraintEqualToConstant:40].active = YES;

  NSDictionary *info = [NSBundle mainBundle].infoDictionary;
  UILabel *version = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote
                                       color:UIColor.mdb_textSecondary];
  version.text = [NSString
      stringWithFormat:@"Version %@ (%@)", info[@"CFBundleShortVersionString"] ?: @"1.0", info[@"CFBundleVersion"] ?: @"1"];
  version.textAlignment = NSTextAlignmentCenter;

  UIStackView *content = [[UIStackView alloc]
      initWithArrangedSubviews:@[ logo, version, [self makeAttributionCard], [self makeLinks], [self makeFooter] ]];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  content.axis = UILayoutConstraintAxisVertical;
  content.spacing = 24;
  [content setCustomSpacing:8 afterView:logo];
  [scrollView addSubview:content];

  [NSLayoutConstraint activateConstraints:@[
    [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [content.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20],
    [content.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20],
    [content.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor constant:32],
    [content.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor constant:-32],
    [content.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40],
  ]];
}

- (UIView *)makeAttributionCard {
  UILabel *caption = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1
                                       color:UIColor.mdb_textSecondary];
  caption.text = @"Movie data and images provided by";
  caption.textAlignment = NSTextAlignmentCenter;

  // Stand-in mark in TMDB's brand colors. Swap it for the official logo from
  // themoviedb.org/about/logos-attribution before shipping to the App Store.
  UILabel *mark = [[UILabel alloc] init];
  mark.text = @"TMDB";
  mark.font = [UIFont systemFontOfSize:22 weight:UIFontWeightHeavy];
  mark.textColor = [UIColor mdb_colorWithHex:0x0D253F alpha:1];
  mark.textAlignment = NSTextAlignmentCenter;
  mark.backgroundColor = [UIColor mdb_colorWithHex:0x01B4E4 alpha:1];
  mark.layer.cornerRadius = 8;
  mark.clipsToBounds = YES;
  mark.accessibilityLabel = @"The Movie Database";
  [NSLayoutConstraint activateConstraints:@[
    [mark.widthAnchor constraintEqualToConstant:110],
    [mark.heightAnchor constraintEqualToConstant:40],
  ]];

  UILabel *notice = [MDBTheme labelWithSize:13 weight:UIFontWeightRegular textStyle:UIFontTextStyleFootnote
                                      color:[UIColor colorWithWhite:1 alpha:0.8]];
  notice.text = @"This product uses the TMDB API but is not endorsed or certified by TMDB.";
  notice.numberOfLines = 0;
  notice.textAlignment = NSTextAlignmentCenter;

  UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ caption, mark, notice ]];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  stack.axis = UILayoutConstraintAxisVertical;
  stack.alignment = UIStackViewAlignmentCenter;
  stack.spacing = 14;

  UIView *card = [[UIView alloc] init];
  card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.04];
  card.layer.cornerRadius = 12;
  card.layer.borderWidth = 1;
  card.layer.borderColor = UIColor.mdb_separator.CGColor;
  [card addSubview:stack];
  [NSLayoutConstraint activateConstraints:@[
    [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
    [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
    [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
    [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20],
    [notice.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
  ]];
  return card;
}

- (UIView *)makeLinks {
  MDBListRowButton *tmdb = [MDBListRowButton rowWithSymbolName:@"globe" title:@"TMDB website"];
  tmdb.tag = 0;
  MDBListRowButton *github = [MDBListRowButton rowWithSymbolName:@"chevron.left.forwardslash.chevron.right"
                                                           title:@"Source code on GitHub"];
  github.tag = 1;
  MDBListRowButton *attribution = [MDBListRowButton rowWithSymbolName:@"info.circle" title:@"TMDB attribution rules"];
  attribution.tag = 2;
  for (MDBListRowButton *row in @[ tmdb, github, attribution ]) {
    [row addTarget:self action:@selector(linkTapped:) forControlEvents:UIControlEventTouchUpInside];
  }
  UIStackView *rows = [[UIStackView alloc] initWithArrangedSubviews:@[ tmdb, github, attribution ]];
  rows.axis = UILayoutConstraintAxisVertical;
  return rows;
}

- (UIView *)makeFooter {
  UILabel *footer = [MDBTheme labelWithSize:11 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption2
                                      color:UIColor.mdb_textTertiary];
  footer.text = @"Built by Adam Daris Ryadhi. Design based on the Nusantara Beta Studio onboarding project.";
  footer.numberOfLines = 0;
  footer.textAlignment = NSTextAlignmentCenter;
  return footer;
}

- (void)linkTapped:(UIButton *)sender {
  NSArray<NSString *> *links = @[ MDBTMDBURL, MDBRepositoryURL, MDBAttributionURL ];
  if (sender.tag < 0 || sender.tag >= (NSInteger)links.count) {
    return;
  }
  NSURL *url = [NSURL URLWithString:links[(NSUInteger)sender.tag]];
  if (url) {
    [self.delegate aboutViewController:self openURL:url];
  }
}

@end
