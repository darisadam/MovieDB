//
//  MDBCoreDataStack.m
//  MovieDB
//

#import "MDBCoreDataStack.h"
#import "MDBLog.h"

NSString *const MDBFavoriteEntityName = @"FavoriteMovie";

@implementation MDBCoreDataStack

+ (NSAttributeDescription *)attributeNamed:(NSString *)name type:(NSAttributeType)type optional:(BOOL)optional {
  NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
  attribute.name = name;
  attribute.attributeType = type;
  attribute.optional = optional;
  return attribute;
}

+ (NSManagedObjectModel *)managedObjectModel {
  // One model instance per process. Core Data complains when two models claim the same entity.
  static NSManagedObjectModel *model;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSEntityDescription *favorite = [[NSEntityDescription alloc] init];
    favorite.name = MDBFavoriteEntityName;
    favorite.managedObjectClassName = NSStringFromClass([NSManagedObject class]);

    NSAttributeDescription *movieID = [self attributeNamed:@"movieID" type:NSInteger64AttributeType optional:NO];
    NSAttributeDescription *voteAverage = [self attributeNamed:@"voteAverage" type:NSDoubleAttributeType optional:NO];
    voteAverage.defaultValue = @0;
    NSAttributeDescription *voteCount = [self attributeNamed:@"voteCount" type:NSInteger64AttributeType optional:NO];
    voteCount.defaultValue = @0;

    favorite.properties = @[
      movieID,
      [self attributeNamed:@"title" type:NSStringAttributeType optional:NO],
      [self attributeNamed:@"overview" type:NSStringAttributeType optional:YES],
      [self attributeNamed:@"posterPath" type:NSStringAttributeType optional:YES],
      [self attributeNamed:@"releaseDate" type:NSDateAttributeType optional:YES],
      voteAverage,
      voteCount,
      [self attributeNamed:@"genreNames" type:NSStringAttributeType optional:YES],
      [self attributeNamed:@"addedAt" type:NSDateAttributeType optional:NO],
    ];
    favorite.uniquenessConstraints = @[ @[ @"movieID" ] ];

    NSFetchIndexElementDescription *element =
        [[NSFetchIndexElementDescription alloc] initWithProperty:movieID collationType:NSFetchIndexElementTypeBinary];
    favorite.indexes = @[ [[NSFetchIndexDescription alloc] initWithName:@"byMovieID" elements:@[ element ]] ];

    model = [[NSManagedObjectModel alloc] init];
    model.entities = @[ favorite ];
  });
  return model;
}

- (instancetype)initWithStoreType:(MDBCoreDataStoreType)storeType {
  self = [super init];
  if (self) {
    _container = [[NSPersistentContainer alloc] initWithName:@"MovieDB" managedObjectModel:[self.class managedObjectModel]];
    NSPersistentStoreDescription *description = _container.persistentStoreDescriptions.firstObject;
    if (storeType == MDBCoreDataStoreTypeInMemory || !description) {
      description = [self.class inMemoryDescription];
      _container.persistentStoreDescriptions = @[ description ];
    } else {
      [description setOption:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSPersistentStoreFileProtectionKey];
    }
    description.shouldAddStoreAsynchronously = NO;

    __block NSError *loadError = nil;
    [_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *store, NSError *error) {
      loadError = error;
    }];

    if (loadError) {
      // Favorites are a convenience, not critical data. Keep the app usable and say so loudly.
      MDBLogFault(MDBLogCategoryPersistence, @"Could not open favorites store, using memory instead: %@", loadError);
      _loadError = loadError;
      _container = [[NSPersistentContainer alloc] initWithName:@"MovieDB" managedObjectModel:[self.class managedObjectModel]];
      _container.persistentStoreDescriptions = @[ [self.class inMemoryDescription] ];
      [_container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *store, NSError *error) {
        if (error) {
          MDBLogFault(MDBLogCategoryPersistence, @"In-memory store failed too: %@", error);
        }
      }];
    } else {
      MDBLogInfo(MDBLogCategoryPersistence, @"Favorites store ready at %@", description.URL.path ?: @"memory");
    }

    _container.viewContext.automaticallyMergesChangesFromParent = YES;
    _container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _container.viewContext.name = @"viewContext";
  }
  return self;
}

+ (NSPersistentStoreDescription *)inMemoryDescription {
  NSPersistentStoreDescription *description = [[NSPersistentStoreDescription alloc] init];
  description.type = NSInMemoryStoreType;
  description.shouldAddStoreAsynchronously = NO;
  return description;
}

- (NSManagedObjectContext *)viewContext {
  return self.container.viewContext;
}

- (NSManagedObjectContext *)newBackgroundContext {
  NSManagedObjectContext *context = [self.container newBackgroundContext];
  context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
  context.name = @"backgroundContext";
  return context;
}

@end
