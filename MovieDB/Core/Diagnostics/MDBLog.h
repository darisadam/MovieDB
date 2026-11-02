//
//  MDBLog.h
//  MovieDB
//
//  Thin wrapper over os_log. Use the macros at the bottom, they add file and line for you.
//  Filter in Console.app with subsystem com.adamappstudio.moviedb.
//

#import <Foundation/Foundation.h>
#import <os/log.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MDBLogCategory) {
  MDBLogCategoryApp = 0,
  MDBLogCategoryNetwork,
  MDBLogCategoryUI,
  MDBLogCategoryPersistence,
  MDBLogCategoryCoordinator,
  MDBLogCategoryMetrics,
};

typedef NS_ENUM(NSInteger, MDBLogLevel) {
  MDBLogLevelDebug = 0,
  MDBLogLevelInfo = 1,
  MDBLogLevelError = 2,
  MDBLogLevelFault = 3,
};

FOUNDATION_EXPORT NSString *const MDBLogSubsystem;

FOUNDATION_EXPORT os_log_t MDBLogHandle(MDBLogCategory category);
FOUNDATION_EXPORT void MDBLogSetMinimumLevel(MDBLogLevel level);
FOUNDATION_EXPORT MDBLogLevel MDBLogMinimumLevel(void);
FOUNDATION_EXPORT void MDBLogWrite(MDBLogCategory category, MDBLogLevel level, const char *file, int line, NSString *format, ...)
    NS_FORMAT_FUNCTION(5, 6);

/// The last few hundred lines, newest last. Debug builds only, empty in Release.
FOUNDATION_EXPORT NSArray<NSString *> *MDBLogRecentLines(void);

/// Called on every fault. Set a symbolic breakpoint on it to stop right where things went wrong.
FOUNDATION_EXPORT void MDBLogFaultHook(void);

NS_ASSUME_NONNULL_END

#if DEBUG
#define MDBLogDebug(category, ...) MDBLogWrite((category), MDBLogLevelDebug, __FILE_NAME__, __LINE__, __VA_ARGS__)
#else
// Compiled out, but the arguments are still type-checked so Release builds don't flag log-only variables as unused.
#define MDBLogDebug(category, ...)                                                     \
  do {                                                                                 \
    if (0) {                                                                           \
      MDBLogWrite((category), MDBLogLevelDebug, __FILE_NAME__, __LINE__, __VA_ARGS__); \
    }                                                                                  \
  } while (0)
#endif
#define MDBLogInfo(category, ...) MDBLogWrite((category), MDBLogLevelInfo, __FILE_NAME__, __LINE__, __VA_ARGS__)
#define MDBLogError(category, ...) MDBLogWrite((category), MDBLogLevelError, __FILE_NAME__, __LINE__, __VA_ARGS__)
#define MDBLogFault(category, ...) MDBLogWrite((category), MDBLogLevelFault, __FILE_NAME__, __LINE__, __VA_ARGS__)
