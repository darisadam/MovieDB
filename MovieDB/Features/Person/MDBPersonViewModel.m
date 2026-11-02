//
//  MDBPersonViewModel.m
//  MovieDB
//

#import "MDBPersonViewModel.h"
#import "MDBAPIError.h"
#import "MDBFormatting.h"
#import "MDBImageURLBuilder.h"
#import "MDBMovie.h"
#import "MDBMovieCellModel.h"
#import "MDBObservable.h"
#import "MDBPerson.h"
#import "MDBScreenState.h"

static const NSUInteger MDBFilmographyLimit = 30;

@implementation MDBFilmographyRow

- (instancetype)initWithMovie:(MDBMovieCellModel *)movie roleText:(NSString *)roleText {
  self = [super init];
  if (self) {
    _movie = movie;
    _title = [movie.title copy];
    _yearText = movie.yearText.length > 0 ? [movie.yearText copy] : @"TBA";
    _roleText = [roleText copy];
  }
  return self;
}

@end

@implementation MDBPersonFact

- (instancetype)initWithTitle:(NSString *)title value:(NSString *)value {
  self = [super init];
  if (self) {
    _title = [title copy];
    _value = [value copy];
  }
  return self;
}

@end

@interface MDBPersonContent ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite, nullable) NSURL *profileURL;
@property (nonatomic, copy, readwrite) NSString *departmentText;
@property (nonatomic, copy, readwrite) NSArray<MDBPersonFact *> *facts;
@property (nonatomic, copy, readwrite) NSString *biography;
@property (nonatomic, copy, readwrite) NSArray<MDBMovieCellModel *> *knownFor;
@property (nonatomic, copy, readwrite) NSArray<MDBFilmographyRow *> *filmography;
@end

@implementation MDBPersonContent

+ (instancetype)placeholderWithName:(NSString *)name {
  MDBPersonContent *content = [[self alloc] init];
  content.name = name;
  content.departmentText = @"";
  content.facts = @[];
  content.biography = @"";
  content.knownFor = @[];
  content.filmography = @[];
  return content;
}

@end

@interface MDBPersonViewModel ()
@property (nonatomic, readonly) NSInteger personID;
@property (nonatomic, copy, readonly) NSString *seedName;
@property (nonatomic, readonly) MDBPersonServices services;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, readonly) MDBSubject<MDBScreenState<MDBPersonContent *> *> *subject;
@property (nonatomic, nullable) id<MDBCancellable> task;
@end

@implementation MDBPersonViewModel

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                        services:(MDBPersonServices)services
                       imageURLs:(MDBImageURLBuilder *)imageURLs {
  self = [super init];
  if (self) {
    _personID = personID;
    _seedName = [name copy];
    _services = services;
    _imageURLs = imageURLs;
    _now = [NSDate date];
    _subject = [[MDBSubject alloc] initWithValue:[MDBScreenState loadingWithContent:[MDBPersonContent placeholderWithName:name]]];
  }
  return self;
}

- (void)dealloc {
  [_task cancel];
}

- (MDBObservable<MDBScreenState<MDBPersonContent *> *> *)state {
  return self.subject;
}

- (void)load {
  [self.task cancel];
  MDBPersonContent *placeholder = [MDBPersonContent placeholderWithName:self.seedName];
  [self.subject send:[MDBScreenState loadingWithContent:placeholder]];

  __weak typeof(self) weakSelf = self;
  self.task = [self.services fetchPersonWithID:self.personID completion:^(MDBPerson *person, NSError *error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf || error.mdb_isCancelled) {
      return;
    }
    if (person) {
      [strongSelf.subject send:[MDBScreenState loadedWithContent:[strongSelf contentForPerson:person]]];
    } else {
      [strongSelf.subject send:[MDBScreenState failedWithError:error content:placeholder]];
    }
  }];
}

#pragma mark - Building content

- (MDBPersonContent *)contentForPerson:(MDBPerson *)person {
  MDBPersonContent *content = [[MDBPersonContent alloc] init];
  content.name = person.name;
  content.profileURL = [self.imageURLs URLForPath:person.profilePath size:MDBImageSizeProfileLarge];
  content.departmentText = person.knownForDepartment ?: @"";
  content.facts = [self factsForPerson:person];
  NSString *biography = person.biography;
  content.biography =
      biography.length > 0 ? biography : [NSString stringWithFormat:@"TMDB doesn't have a biography for %@ yet.", person.name];

  NSDictionary<NSNumber *, NSString *> *genreNames = self.services.genreNames.value;
  NSMutableArray<MDBMovieCellModel *> *knownFor = [NSMutableArray array];
  for (MDBPersonCredit *credit in person.knownFor) {
    [knownFor addObjectsFromArray:[MDBMovieCellModel modelsWithMovies:@[ credit.movie ] genreNames:genreNames
                                                            imageURLs:self.imageURLs]];
  }
  content.knownFor = knownFor;

  NSArray<MDBPersonCredit *> *credits =
      [person.filmography subarrayWithRange:NSMakeRange(0, MIN(person.filmography.count, MDBFilmographyLimit))];
  NSMutableArray<MDBFilmographyRow *> *rows = [NSMutableArray arrayWithCapacity:credits.count];
  for (MDBPersonCredit *credit in credits) {
    MDBMovieCellModel *movie =
        [MDBMovieCellModel modelsWithMovies:@[ credit.movie ] genreNames:genreNames imageURLs:self.imageURLs].firstObject;
    NSString *character = credit.character;
    NSString *role = character.length > 0 ? [@"as " stringByAppendingString:character] : @"";
    if (movie) {
      [rows addObject:[[MDBFilmographyRow alloc] initWithMovie:movie roleText:role]];
    }
  }
  content.filmography = rows;
  return content;
}

- (NSArray<MDBPersonFact *> *)factsForPerson:(MDBPerson *)person {
  NSMutableArray<MDBPersonFact *> *facts = [NSMutableArray array];
  NSDate *birthday = person.birthday;
  NSDate *deathday = person.deathday;
  if (birthday) {
    NSString *born = [MDBFormatting mediumDateStringFromDate:birthday];
    if (!deathday) {
      born = [NSString stringWithFormat:@"%@ (%ld)", born, (long)[MDBFormatting yearsFromDate:birthday toDate:self.now]];
    }
    [facts addObject:[[MDBPersonFact alloc] initWithTitle:@"Born" value:born]];
  }
  if (deathday) {
    [facts addObject:[[MDBPersonFact alloc] initWithTitle:@"Died" value:[MDBFormatting mediumDateStringFromDate:deathday]]];
  }
  NSString *place = person.placeOfBirth;
  if (place.length > 0) {
    [facts addObject:[[MDBPersonFact alloc] initWithTitle:@"Place of birth" value:place]];
  }
  NSString *credits = [NSString stringWithFormat:@"%lu", (unsigned long)person.filmography.count];
  [facts addObject:[[MDBPersonFact alloc] initWithTitle:@"Known credits" value:credits]];
  return facts;
}

@end
