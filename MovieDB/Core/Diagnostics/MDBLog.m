//
//  MDBLog.m
//  MovieDB
//

#import "MDBLog.h"
#import <stdatomic.h>

NSString *const MDBLogSubsystem = @"com.adamappstudio.moviedb";

enum { MDBLogCategoryCount = 6 };
#if DEBUG
static atomic_long MDBLogLevelThreshold = MDBLogLevelDebug;
#else
static atomic_long MDBLogLevelThreshold = MDBLogLevelInfo;
#endif

os_log_t MDBLogHandle(MDBLogCategory category) {
  static os_log_t handles[MDBLogCategoryCount];
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    const char *names[MDBLogCategoryCount] = {"app", "network", "ui", "persistence", "coordinator", "metrics"};
    for (NSUInteger index = 0; index < MDBLogCategoryCount; index++) {
      handles[index] = os_log_create(MDBLogSubsystem.UTF8String, names[index]);
    }
  });
  NSUInteger index = category < MDBLogCategoryCount ? category : MDBLogCategoryApp;
  return handles[index];
}

void MDBLogSetMinimumLevel(MDBLogLevel level) {
  atomic_store(&MDBLogLevelThreshold, (long)MAX(MDBLogLevelDebug, MIN(MDBLogLevelFault, level)));
}

MDBLogLevel MDBLogMinimumLevel(void) {
  return (MDBLogLevel)atomic_load(&MDBLogLevelThreshold);
}

// The in-memory log buffer only backs the Debug menu, so Release builds leave it out.
#if DEBUG
static const NSUInteger MDBLogRecentLimit = 300;

static dispatch_queue_t MDBLogRecentQueue(void) {
  static dispatch_queue_t queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("com.adamappstudio.moviedb.log.recent", DISPATCH_QUEUE_SERIAL);
  });
  return queue;
}

static NSMutableArray<NSString *> *MDBLogRecentStorage(void) {
  static NSMutableArray<NSString *> *storage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    storage = [NSMutableArray arrayWithCapacity:MDBLogRecentLimit];
  });
  return storage;
}
#endif

static NSString *MDBLogLevelTag(MDBLogLevel level) {
  switch (level) {
    case MDBLogLevelDebug: return @"DEBUG";
    case MDBLogLevelInfo: return @"INFO";
    case MDBLogLevelError: return @"ERROR";
    case MDBLogLevelFault: return @"FAULT";
  }
  return @"LOG";
}

__attribute__((noinline)) void MDBLogFaultHook(void) {
  // Empty on purpose. The asm keeps the optimizer from removing the symbol.
  __asm__ volatile("");
}

void MDBLogWrite(MDBLogCategory category, MDBLogLevel level, const char *file, int line, NSString *format, ...) {
  if (level < MDBLogMinimumLevel()) {
    return;
  }

  va_list arguments;
  va_start(arguments, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
  va_end(arguments);

  os_log_type_t type = OS_LOG_TYPE_DEFAULT;
  switch (level) {
    case MDBLogLevelDebug: type = OS_LOG_TYPE_DEBUG; break;
    case MDBLogLevelInfo: type = OS_LOG_TYPE_INFO; break;
    case MDBLogLevelError: type = OS_LOG_TYPE_ERROR; break;
    case MDBLogLevelFault: type = OS_LOG_TYPE_FAULT; break;
  }

  os_log_t handle = MDBLogHandle(category);
#if DEBUG
  os_log_with_type(handle, type, "[%{public}s:%d] %{public}@", file, line, message);

  static NSDateFormatter *timeFormatter;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"HH:mm:ss.SSS";
  });
  NSString *lineText = [NSString stringWithFormat:@"%@ %@ [%s:%d] %@", [timeFormatter stringFromDate:[NSDate date]],
                                                  MDBLogLevelTag(level), file, line, message];
  dispatch_async(MDBLogRecentQueue(), ^{
    NSMutableArray<NSString *> *storage = MDBLogRecentStorage();
    [storage addObject:lineText];
    if (storage.count > MDBLogRecentLimit) {
      [storage removeObjectsInRange:NSMakeRange(0, storage.count - MDBLogRecentLimit)];
    }
  });
#else
  // Release builds keep the message private so nothing personal ends up in sysdiagnose.
  os_log_with_type(handle, type, "[%{public}s:%d] %{private}@", file, line, message);
  (void)MDBLogLevelTag;
#endif

  if (level == MDBLogLevelFault) {
    MDBLogFaultHook();
  }
}

NSArray<NSString *> *MDBLogRecentLines(void) {
#if DEBUG
  __block NSArray<NSString *> *lines = @[];
  dispatch_sync(MDBLogRecentQueue(), ^{
    lines = [MDBLogRecentStorage() copy];
  });
  return lines;
#else
  return @[];
#endif
}
