//
//  MDBObservableTests.m
//  MovieDBTests
//

#import <XCTest/XCTest.h>
#import "MDBObservable.h"
#import "MDBScreenState.h"
#import "MDBTestSupport.h"

@interface MDBObservableTests : XCTestCase
@end

@implementation MDBObservableTests

- (void)testSubscribeReplaysCurrentValueThenFollowsChanges {
  MDBSubject<NSNumber *> *subject = [[MDBSubject alloc] initWithValue:@1];
  NSMutableArray<NSNumber *> *received = [NSMutableArray array];
  id<MDBDisposable> subscription = [subject subscribe:^(NSNumber *value) {
    [received addObject:value];
  }];
  [subject send:@2];
  [subject send:@3];
  XCTAssertEqualObjects(received, (@[ @1, @2, @3 ]));
  [subscription dispose];
}

- (void)testSubjectWithoutValueDoesNotReplay {
  MDBSubject<NSString *> *subject = [[MDBSubject alloc] init];
  __block NSUInteger calls = 0;
  [subject subscribe:^(NSString *value) {
    calls += 1;
  }];
  XCTAssertEqual(calls, 0u);
  XCTAssertFalse(subject.hasValue);
  [subject send:@"first"];
  XCTAssertEqual(calls, 1u);
}

- (void)testDisposeStopsDelivery {
  MDBSubject<NSNumber *> *subject = [[MDBSubject alloc] initWithValue:@0];
  __block NSInteger last = -1;
  id<MDBDisposable> subscription = [subject subscribe:^(NSNumber *value) {
    last = value.integerValue;
  }];
  [subscription dispose];
  [subject send:@5];
  XCTAssertEqual(last, 0);
}

- (void)testMapFilterAndDistinct {
  MDBSubject<NSNumber *> *subject = [[MDBSubject alloc] initWithValue:@1];
  NSMutableArray *received = [NSMutableArray array];
  MDBObservable *chain = [[[subject map:^id(NSNumber *value) {
    return @(value.integerValue * 10);
  }] filter:^BOOL(NSNumber *value) {
    return value.integerValue > 10;
  }] distinctUntilChanged];
  id<MDBDisposable> subscription = [chain subscribe:^(id value) {
    [received addObject:value];
  }];
  [subject send:@2];
  [subject send:@2];
  [subject send:@3];
  XCTAssertEqualObjects(received, (@[ @20, @30 ]));
  [subscription dispose];
}

- (void)testSkipIgnoresTheReplayedValue {
  MDBSubject<NSString *> *subject = [[MDBSubject alloc] initWithValue:@"current"];
  NSMutableArray *received = [NSMutableArray array];
  id<MDBDisposable> subscription = [[subject skip:1] subscribe:^(id value) {
    [received addObject:value];
  }];
  [subject send:@"next"];
  XCTAssertEqualObjects(received, @[ @"next" ]);
  [subscription dispose];
}

- (void)testDebounceOnlyEmitsTheLastValue {
  MDBSubject<NSString *> *subject = [[MDBSubject alloc] init];
  NSMutableArray *received = [NSMutableArray array];
  id<MDBDisposable> subscription = [[subject debounce:0.05] subscribe:^(id value) {
    [received addObject:value];
  }];
  [subject send:@"m"];
  [subject send:@"ma"];
  [subject send:@"maze"];
  XCTAssertEqual(received.count, 0u, @"Nothing should arrive before the quiet period");
  XCTAssertTrue(MDBWaitUntil(^BOOL {
    return received.count > 0;
  }));
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
  XCTAssertEqualObjects(received, @[ @"maze" ]);
  [subscription dispose];
}

- (void)testCombineLatestWaitsForBothSides {
  MDBSubject<NSNumber *> *left = [[MDBSubject alloc] init];
  MDBSubject<NSNumber *> *right = [[MDBSubject alloc] initWithValue:@10];
  NSMutableArray *received = [NSMutableArray array];
  MDBObservable *sum = [MDBObservable combineLatest:left
                                               with:right
                                             reduce:^id(NSNumber *a, NSNumber *b) {
                                               return @(a.integerValue + b.integerValue);
                                             }];
  id<MDBDisposable> subscription = [sum subscribe:^(id value) {
    [received addObject:value];
  }];
  XCTAssertEqual(received.count, 0u);
  [left send:@1];
  [right send:@20];
  XCTAssertEqualObjects(received, (@[ @11, @21 ]));
  [subscription dispose];
}

- (void)testDerivedStreamDoesNotKeepItselfAlive {
  MDBSubject<NSNumber *> *subject = [[MDBSubject alloc] initWithValue:@1];
  __weak MDBObservable *weakDerived = nil;
  @autoreleasepool {
    MDBObservable *derived = [subject map:^id(id value) {
      return value;
    }];
    id<MDBDisposable> subscription = [derived subscribe:^(id value){
    }];
    weakDerived = derived;
    [subscription dispose];
  }
  XCTAssertNil(weakDerived, @"The source must only hold derived streams weakly");
}

- (void)testDisposeBagDisposesOnDealloc {
  MDBSubject<NSNumber *> *subject = [[MDBSubject alloc] initWithValue:@0];
  __block NSUInteger calls = 0;
  @autoreleasepool {
    MDBDisposeBag *bag = [[MDBDisposeBag alloc] init];
    [bag addDisposable:[subject subscribe:^(id value) {
           calls += 1;
         }]];
  }
  [subject send:@1];
  XCTAssertEqual(calls, 1u, @"Only the replayed value, nothing after the bag went away");
}

- (void)testScreenStateMapKeepsPhaseAndError {
  NSError *error = [NSError errorWithDomain:@"test" code:7 userInfo:nil];
  MDBScreenState *failed = [MDBScreenState failedWithError:error content:@"raw"];
  MDBScreenState *mapped = [failed mapContent:^id(NSString *content) {
    return content.uppercaseString;
  }];
  XCTAssertEqual(mapped.phase, MDBLoadStateFailed);
  XCTAssertEqualObjects(mapped.error, error);
  XCTAssertEqualObjects(mapped.content, @"RAW");
  XCTAssertNil([[MDBScreenState empty] mapContent:^id(id content) {
                 return @"never";
               }].content);
}

@end
