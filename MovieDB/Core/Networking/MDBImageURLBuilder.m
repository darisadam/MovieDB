//
//  MDBImageURLBuilder.m
//  MovieDB
//

#import "MDBImageURLBuilder.h"

@interface MDBImageURLBuilder ()
@property (nonatomic, copy, readonly) NSURL *baseURL;
@end

@implementation MDBImageURLBuilder

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
  self = [super init];
  if (self) {
    _baseURL = [baseURL copy];
  }
  return self;
}

- (nullable NSURL *)URLForPath:(nullable NSString *)path size:(MDBImageSize)size {
  if (path.length == 0) {
    return nil;
  }
  NSString *sizeComponent = @"w342";
  switch (size) {
    case MDBImageSizePosterSmall: sizeComponent = @"w185"; break;
    case MDBImageSizePoster: sizeComponent = @"w342"; break;
    case MDBImageSizeBackdrop: sizeComponent = @"w780"; break;
    case MDBImageSizeProfile: sizeComponent = @"w185"; break;
    case MDBImageSizeProfileLarge: sizeComponent = @"h632"; break;
  }
  NSString *cleanPath = [path hasPrefix:@"/"] ? [path substringFromIndex:1] : path;
  NSString *relative = [NSString stringWithFormat:@"%@/%@", sizeComponent ?: @"w342", cleanPath];
  return [NSURL URLWithString:relative relativeToURL:self.baseURL].absoluteURL;
}

@end
