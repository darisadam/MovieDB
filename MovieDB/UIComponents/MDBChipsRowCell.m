//
//  MDBChipsRowCell.m
//  MovieDB
//

#import "MDBChipsRowCell.h"
#import "MDBButtonFactory.h"

@interface MDBChipsRowCell ()
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIStackView *stack;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@end

@implementation MDBChipsRowCell

+ (NSString *)identifier {
  return @"MDBChipsRowCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _titles = @[];
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
    [self.contentView addSubview:_scrollView];

    _stack = [[UIStackView alloc] init];
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    _stack.spacing = 8;
    [_scrollView addSubview:_stack];

    [NSLayoutConstraint activateConstraints:@[
      [_scrollView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
      [_scrollView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
      [_scrollView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [_scrollView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
      [_stack.leadingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.leadingAnchor],
      [_stack.trailingAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.trailingAnchor],
      [_stack.topAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.topAnchor],
      [_stack.bottomAnchor constraintEqualToAnchor:_scrollView.contentLayoutGuide.bottomAnchor],
      [_stack.heightAnchor constraintEqualToAnchor:_scrollView.frameLayoutGuide.heightAnchor],
      [self.contentView.heightAnchor constraintGreaterThanOrEqualToConstant:36],
    ]];
  }
  return self;
}

- (void)configureWithTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex {
  if (![titles isEqualToArray:self.titles]) {
    self.titles = titles;
    for (UIView *view in self.stack.arrangedSubviews) {
      [view removeFromSuperview];
    }
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
      UIButton *chip = [MDBButtonFactory chipWithTitle:title];
      chip.tag = (NSInteger)index;
      [chip addTarget:self action:@selector(chipTapped:) forControlEvents:UIControlEventTouchUpInside];
      [self.stack addArrangedSubview:chip];
    }];
  }
  for (UIView *view in self.stack.arrangedSubviews) {
    if ([view isKindOfClass:[UIButton class]]) {
      [MDBButtonFactory setChip:(UIButton *)view selected:view.tag == selectedIndex];
    }
  }
}

- (void)chipTapped:(UIButton *)sender {
  if (self.onSelectIndex) {
    self.onSelectIndex(sender.tag);
  }
}

@end
