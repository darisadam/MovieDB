//
//  MDBTrailerViewController.m
//  MovieDB
//

#import "MDBTrailerViewController.h"
#import "MDBButtonFactory.h"
#import "MDBLog.h"
#import "MDBTheme.h"
#import "MDBVideo.h"
#import <SDWebImage/SDWebImage.h>
#import <WebKit/WebKit.h>

@interface MDBTrailerViewController () <UITableViewDataSource, UITableViewDelegate, WKNavigationDelegate>
@property (nonatomic, copy, readonly) NSArray<MDBVideo *> *videos;
@property (nonatomic, copy, readonly) NSString *movieTitle;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) WKWebView *webView;
@property (nonatomic) UILabel *videoTitleLabel;
@property (nonatomic) UILabel *videoMetaLabel;
@property (nonatomic) UITableView *tableView;
@end

@implementation MDBTrailerViewController

- (instancetype)initWithVideos:(NSArray<MDBVideo *> *)videos movieTitle:(NSString *)movieTitle {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _videos = [videos copy];
        _movieTitle = [movieTitle copy];
    }
    return self;
}

- (void)dealloc {
    // Stops audio right away if the sheet goes away mid playback.
    [_webView stopLoading];
    _webView.navigationDelegate = nil;
}

+ (NSString *)embedHTMLForVideoKey:(NSString *)videoKey {
    // Keys are short base64url ids. Anything else is dropped so the key can't break out of the HTML.
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"];
    NSString *safeKey = [[videoKey componentsSeparatedByCharactersInSet:allowed.invertedSet] componentsJoinedByString:@""];
    return [NSString stringWithFormat:
            @"<!doctype html><html><head><meta name='viewport' content='width=device-width,initial-scale=1'>"
            @"<style>html,body{margin:0;background:#000;height:100%%}iframe{position:absolute;inset:0;width:100%%;height:100%%;border:0}</style>"
            @"</head><body><iframe src='https://www.youtube-nocookie.com/embed/%@?playsinline=1&rel=0&modestbranding=1' "
            @"referrerpolicy='strict-origin-when-cross-origin' allow='autoplay; encrypted-media; picture-in-picture; fullscreen' "
            @"allowfullscreen></iframe></body></html>", safeKey];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.mdb_surface;

    UILabel *header = [MDBTheme labelWithSize:17 weight:UIFontWeightSemibold textStyle:UIFontTextStyleHeadline color:UIColor.mdb_textPrimary];
    header.text = @"Trailers & Videos";
    header.accessibilityTraits = UIAccessibilityTraitHeader;

    UIButtonConfiguration *closeConfig = [UIButtonConfiguration plainButtonConfiguration];
    closeConfig.image = [UIImage systemImageNamed:@"xmark.circle.fill"
                                withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular]];
    closeConfig.baseForegroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    UIButton *close = [UIButton buttonWithConfiguration:closeConfig primaryAction:nil];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    close.accessibilityLabel = @"Close";
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    configuration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.backgroundColor = UIColor.blackColor;
    self.webView.opaque = NO;
    self.webView.scrollView.scrollEnabled = NO;
    self.webView.layer.cornerRadius = 10;
    self.webView.clipsToBounds = YES;
#if DEBUG
    if (@available(iOS 16.4, *)) {
        // Lets you attach Safari's Web Inspector to the player in debug builds.
        self.webView.inspectable = YES;
    }
#endif

    self.videoTitleLabel = [MDBTheme labelWithSize:15 weight:UIFontWeightSemibold textStyle:UIFontTextStyleSubheadline color:UIColor.mdb_textPrimary];
    self.videoTitleLabel.numberOfLines = 2;
    self.videoMetaLabel = [MDBTheme labelWithSize:12 weight:UIFontWeightRegular textStyle:UIFontTextStyleCaption1 color:UIColor.mdb_textSecondary];

    UIButton *openButton = [MDBButtonFactory buttonWithStyle:MDBButtonStyleSecondary title:@"Open in YouTube" symbolName:@"arrow.up.right.square"];
    [openButton addTarget:self action:@selector(openExternallyTapped) forControlEvents:UIControlEventTouchUpInside];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = UIColor.mdb_separator;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 76;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"VideoCell"];

    for (UIView *view in @[header, close, self.webView, self.videoTitleLabel, self.videoMetaLabel, openButton, self.tableView]) {
        [self.view addSubview:view];
    }

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [header.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [header.topAnchor constraintEqualToAnchor:guide.topAnchor constant:22],
        [close.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-12],
        [close.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:20],
        [self.webView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-20],
        [self.webView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:16],
        [self.webView.heightAnchor constraintEqualToAnchor:self.webView.widthAnchor multiplier:9.0 / 16.0],
        [self.videoTitleLabel.leadingAnchor constraintEqualToAnchor:self.webView.leadingAnchor],
        [self.videoTitleLabel.trailingAnchor constraintEqualToAnchor:self.webView.trailingAnchor],
        [self.videoTitleLabel.topAnchor constraintEqualToAnchor:self.webView.bottomAnchor constant:14],
        [self.videoMetaLabel.leadingAnchor constraintEqualToAnchor:self.webView.leadingAnchor],
        [self.videoMetaLabel.topAnchor constraintEqualToAnchor:self.videoTitleLabel.bottomAnchor constant:4],
        [openButton.leadingAnchor constraintEqualToAnchor:self.webView.leadingAnchor],
        [openButton.topAnchor constraintEqualToAnchor:self.videoMetaLabel.bottomAnchor constant:14],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:openButton.bottomAnchor constant:16],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self showVideoAtIndex:0];
}

- (void)showVideoAtIndex:(NSUInteger)index {
    if (index >= self.videos.count) {
        return;
    }
    self.selectedIndex = index;
    MDBVideo *video = self.videos[index];
    self.videoTitleLabel.text = video.name;
    self.videoMetaLabel.text = [NSString stringWithFormat:@"%@ · YouTube%@", video.type, video.isOfficial ? @" · Official" : @""];
    // The base URL gives YouTube a referrer, without one the embed refuses to play.
    [self.webView loadHTMLString:[self.class embedHTMLForVideoKey:video.key]
                         baseURL:[NSURL URLWithString:@"https://com.darisadam.moviedb/"]];
    MDBLogInfo(MDBLogCategoryUI, @"Playing %@ for %@", video, self.movieTitle);
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)closeTapped {
    [self.delegate trailerViewControllerDidClose:self];
}

- (void)openExternallyTapped {
    NSURL *url = self.selectedIndex < self.videos.count ? self.videos[self.selectedIndex].watchURL : nil;
    if (url) {
        [self.delegate trailerViewController:self openExternalURL:url];
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.videos.count;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.videos.count > 1 ? @"More videos" : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VideoCell" forIndexPath:indexPath];
    MDBVideo *video = self.videos[(NSUInteger)indexPath.row];
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = video.name;
    content.textProperties.color = UIColor.mdb_textPrimary;
    content.textProperties.numberOfLines = 2;
    content.secondaryText = video.type;
    content.secondaryTextProperties.color = UIColor.mdb_textSecondary;
    content.image = [UIImage systemImageNamed:(NSUInteger)indexPath.row == self.selectedIndex ? @"play.circle.fill" : @"play.circle"];
    content.imageProperties.tintColor = UIColor.mdb_accent;
    cell.contentConfiguration = content;
    cell.backgroundColor = UIColor.clearColor;
    cell.accessibilityTraits = (NSUInteger)indexPath.row == self.selectedIndex
        ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected)
        : UIAccessibilityTraitButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showVideoAtIndex:(NSUInteger)indexPath.row];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    // Taps on the YouTube logo or title try to navigate the frame. Send those out to Safari or the YouTube app.
    if (navigationAction.targetFrame.isMainFrame && navigationAction.navigationType == WKNavigationTypeLinkActivated && url) {
        [self.delegate trailerViewController:self openExternalURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    MDBLogError(MDBLogCategoryUI, @"Trailer failed to load: %@", error.localizedDescription);
}

@end
