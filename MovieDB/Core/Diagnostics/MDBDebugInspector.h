//
//  MDBDebugInspector.h
//  MovieDB
//
//  Class methods meant to be called from LLDB while the app is paused. The aliases in
//  Scripts/lldb/MovieDB.lldbinit wrap them, for example `mdb_net` or `mdb_vc`.
//  Debug builds only.
//

#import <Foundation/Foundation.h>

#if DEBUG

NS_ASSUME_NONNULL_BEGIN

@interface MDBDebugInspector : NSObject

/// View controller hierarchy of the key window, with the visible screen marked.
+ (NSString *)viewControllerTree;
/// Coordinator tree starting at the app coordinator.
+ (NSString *)coordinatorTree;
/// Last network requests, newest first, with status, timing and size.
+ (NSString *)recentRequests;
/// The cURL command for the most recent request, token redacted.
+ (NSString *)lastRequestAsCURL;
/// Saved favorites in the Core Data store.
+ (NSString *)favorites;
/// Last log lines written through MDBLog.
+ (NSString *)recentLogs;
/// Token presence, base URLs, region and language.
+ (NSString *)configuration;

+ (void)setOfflineMode:(BOOL)offline;
+ (void)setLogLevel:(NSInteger)level;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif
