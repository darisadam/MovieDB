//
//  MDBCoreDataStack.h
//  MovieDB
//
//  The model is built in code instead of an .xcdatamodeld, so it is easy to review in a PR.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MDBFavoriteEntityName;

typedef NS_ENUM(NSInteger, MDBCoreDataStoreType) {
  MDBCoreDataStoreTypeSQLite = 0,
  MDBCoreDataStoreTypeInMemory,
};

@interface MDBCoreDataStack : NSObject

@property (nonatomic, readonly) NSPersistentContainer *container;
@property (nonatomic, readonly) NSManagedObjectContext *viewContext;
/// Set when the SQLite store failed to open and we fell back to memory.
@property (nonatomic, readonly, nullable) NSError *loadError;

+ (NSManagedObjectModel *)managedObjectModel;

- (instancetype)initWithStoreType:(MDBCoreDataStoreType)storeType NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSManagedObjectContext *)newBackgroundContext;

@end

NS_ASSUME_NONNULL_END
