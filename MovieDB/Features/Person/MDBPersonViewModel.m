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
#import "MDBPerson.h"

static const NSUInteger MDBFilmographyLimit = 30;

@implementation MDBFilmographyRow

- (instancetype)initWithMovie:(MDBMovieCellModel *)movie roleText:(NSString *)roleText {
    self = [super init];
    if (self) {
        _movie = movie;
        _movieID = movie.movieID;
        _title = [movie.title copy];
        _yearText = movie.yearText.length > 0 ? [movie.yearText copy] : @"TBA";
        _roleText = [roleText copy];
    }
    return self;
}

@end

@interface MDBPersonViewModel ()
@property (nonatomic, readwrite) MDBLoadState state;
@property (nonatomic, readwrite, nullable) NSError *error;
@property (nonatomic, readwrite, nullable) MDBPerson *person;
@property (nonatomic, readonly) NSInteger personID;
@property (nonatomic, copy, readonly) NSString *seedName;
@property (nonatomic, readonly) id<MDBMovieService> movieService;
@property (nonatomic, readonly) MDBImageURLBuilder *imageURLs;
@property (nonatomic, nullable) id<MDBCancellable> task;
@end

@implementation MDBPersonViewModel

- (instancetype)initWithPersonID:(NSInteger)personID
                            name:(NSString *)name
                    movieService:(id<MDBMovieService>)movieService
                       imageURLs:(MDBImageURLBuilder *)imageURLs {
    self = [super init];
    if (self) {
        _personID = personID;
        _seedName = [name copy];
        _movieService = movieService;
        _imageURLs = imageURLs;
    }
    return self;
}

- (void)dealloc {
    [_task cancel];
}

- (void)load {
    [self.task cancel];
    self.state = MDBLoadStateLoading;
    self.error = nil;
    [self notifyChange];

    __weak typeof(self) weakSelf = self;
    self.task = [self.movieService fetchPersonWithID:self.personID completion:^(MDBPerson *person, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || error.mdb_isCancelled) {
            return;
        }
        if (person) {
            strongSelf.person = person;
            strongSelf.state = MDBLoadStateLoaded;
        } else {
            strongSelf.state = MDBLoadStateFailed;
            strongSelf.error = error;
        }
        [strongSelf notifyChange];
    }];
}

- (NSString *)name {
    return self.person.name ?: self.seedName;
}

- (nullable NSURL *)profileURL {
    return [self.imageURLs URLForPath:self.person.profilePath size:MDBImageSizeProfileLarge];
}

- (NSString *)departmentText {
    return self.person.knownForDepartment ?: @"";
}

- (NSArray<NSArray<NSString *> *> *)facts {
    MDBPerson *person = self.person;
    if (!person) {
        return @[];
    }
    NSMutableArray<NSArray<NSString *> *> *facts = [NSMutableArray array];
    NSDate *birthday = person.birthday;
    if (birthday) {
        NSString *born = [MDBFormatting mediumDateStringFromDate:birthday];
        if (!person.deathday) {
            NSInteger age = [MDBFormatting yearsFromDate:birthday toDate:[NSDate date]];
            born = [NSString stringWithFormat:@"%@ (%ld)", born, (long)age];
        }
        [facts addObject:@[@"Born", born]];
    }
    if (person.deathday) {
        [facts addObject:@[@"Died", [MDBFormatting mediumDateStringFromDate:person.deathday]]];
    }
    NSString *place = person.placeOfBirth;
    if (place.length > 0) {
        [facts addObject:@[@"Place of birth", place]];
    }
    [facts addObject:@[@"Known credits", [NSString stringWithFormat:@"%lu", (unsigned long)person.filmography.count]]];
    return facts;
}

- (NSString *)biography {
    NSString *biography = self.person.biography;
    if (biography.length > 0) {
        return biography;
    }
    return self.person ? [NSString stringWithFormat:@"TMDB doesn't have a biography for %@ yet.", self.name] : @"";
}

- (NSArray<MDBMovieCellModel *> *)knownFor {
    NSMutableArray<MDBMovieCellModel *> *models = [NSMutableArray array];
    for (MDBPersonCredit *credit in self.person.knownFor) {
        [models addObject:[self cellModelForMovie:credit.movie]];
    }
    return models;
}

- (NSArray<MDBFilmographyRow *> *)filmography {
    NSArray<MDBPersonCredit *> *credits = self.person.filmography ?: @[];
    NSMutableArray<MDBFilmographyRow *> *rows = [NSMutableArray array];
    for (MDBPersonCredit *credit in [credits subarrayWithRange:NSMakeRange(0, MIN(credits.count, MDBFilmographyLimit))]) {
        NSString *character = credit.character;
        NSString *role = character.length > 0 ? [@"as " stringByAppendingString:character] : @"";
        [rows addObject:[[MDBFilmographyRow alloc] initWithMovie:[self cellModelForMovie:credit.movie] roleText:role]];
    }
    return rows;
}

- (MDBMovieCellModel *)cellModelForMovie:(MDBMovie *)movie {
    return [MDBMovieCellModel modelWithMovie:movie
                                  genreNames:[self.movieService genreNamesForIDs:movie.genreIDs]
                                   imageURLs:self.imageURLs];
}

- (void)notifyChange {
    if (self.onChange) {
        self.onChange();
    }
}

@end
