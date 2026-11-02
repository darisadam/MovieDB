//
//  MDBFormattingTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBFormatting.h"
#import "MDBTrailerViewController.h"

@interface MDBFormattingTests : XCTestCase
@end

@implementation MDBFormattingTests

- (void)testRuntime {
  XCTAssertEqualObjects([MDBFormatting runtimeStringFromMinutes:129], @"2h 9m");
  XCTAssertEqualObjects([MDBFormatting runtimeStringFromMinutes:120], @"2h");
  XCTAssertEqualObjects([MDBFormatting runtimeStringFromMinutes:45], @"45m");
  XCTAssertEqualObjects([MDBFormatting runtimeStringFromMinutes:0], @"");
}

- (void)testCompactCounts {
  XCTAssertEqualObjects([MDBFormatting compactCountStringFromCount:980], @"980");
  XCTAssertEqualObjects([MDBFormatting compactCountStringFromCount:1250], @"1.2k");
  XCTAssertEqualObjects([MDBFormatting compactCountStringFromCount:12034], @"12k");
}

- (void)testCurrency {
  XCTAssertEqualObjects([MDBFormatting compactCurrencyStringFromAmount:90000000], @"$90M");
  XCTAssertEqualObjects([MDBFormatting compactCurrencyStringFromAmount:1200000000], @"$1.2B");
  XCTAssertEqualObjects([MDBFormatting compactCurrencyStringFromAmount:0], @"");
}

- (void)testRatingIsClamped {
  XCTAssertEqualObjects([MDBFormatting ratingStringFromVoteAverage:6.849], @"6.8");
  XCTAssertEqualObjects([MDBFormatting ratingStringFromVoteAverage:12], @"10.0");
}

- (void)testDates {
  NSDate *date = [MDBFormatting dateFromTMDBString:@"1989-07-23"];
  XCTAssertNotNil(date);
  XCTAssertEqualObjects([MDBFormatting yearStringFromDate:date], @"1989");
  XCTAssertNil([MDBFormatting dateFromTMDBString:@""]);
  XCTAssertNil([MDBFormatting dateFromTMDBString:@"soon"]);
  NSDate *later = [MDBFormatting dateFromTMDBString:@"2026-07-22"];
  XCTAssertEqual([MDBFormatting yearsFromDate:date toDate:later], 36);
}

- (void)testTrailerEmbedStripsUnsafeCharacters {
  NSString *html = [MDBTrailerViewController embedHTMLForVideoKey:@"abc'><script>x</script>"];
  XCTAssertFalse([html containsString:@"<script>"]);
  XCTAssertTrue([html containsString:@"embed/abcscriptxscript?"]);
}

@end
