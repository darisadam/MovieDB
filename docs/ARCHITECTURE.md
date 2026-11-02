# Architecture

MovieDB uses **MVVM with coordinators**. Every class is prefixed with `MDB`.

```
SceneDelegate
  └─ MDBAppCoordinator            builds the tab bar, opens the debug menu
       ├─ MDBHomeCoordinator      ┐
       ├─ MDBExploreCoordinator   │ subclasses of MDBMovieFlowCoordinator,
       ├─ MDBFavoritesCoordinator │ which knows how to push detail, person,
       └─ MDBMenuCoordinator      ┘ lists, genre results, trailers and about
```

## The pieces

**Coordinators** decide which screen comes next.
- A view controller never pushes another view controller. It tells its `delegate` what happened, for example `homeViewController:didSelectMovie:`.
- The coordinator builds the next view model and view controller and pushes them.
- Parents hold their children strongly. Children point back to the parent with a `weak` reference.

**View controllers** are built in code with `initWithViewModel:`.
- `initWithCoder:` is marked `NS_UNAVAILABLE`.
- In `viewDidLoad` they subscribe to the view model's observables and keep the subscriptions in an `MDBDisposeBag`. Each update calls a `render:` method with the new state, so there is one place where the screen gets drawn.

**View models** have no UIKit imports.
- They expose read-only `MDBObservable` properties, usually one `state` of type `MDBScreenState<Content>`. A screen state has a `phase` (idle, loading, loaded, empty, failed), the content and an optional error.
- Each view model asks only for the service role it uses, passed in through `init`, so tests can pass stubs.
- Subscriptions and requests are cancelled in `dealloc`.

**Reactive core** (`Core/Reactive`)
- `MDBObservable` holds a current value and replays it to new subscribers. `MDBSubject` is the writable version that view models and stores keep private.
- Operators: `map:`, `filter:`, `distinctUntilChanged`, `skip:`, `debounce:` and `combineLatest`. Explore search is a `query` subject with `debounce:` and `distinctUntilChanged`.
- `subscribe:` returns an `MDBDisposable`. Dropping a dispose bag ends every subscription in it.
- Values arrive on the thread that sent them. View models and stores only send on the main thread.
- It is about 400 lines with no dependency. A full framework like ReactiveObjC would be more than this app needs.

**Services**
- The movie API is split by role: `MDBMovieListProviding`, `MDBMovieSearching`, `MDBMovieDetailProviding`, `MDBPersonProviding` and `MDBGenreProviding`. `MDBMovieService` combines them, and `MDBTMDBMovieService` implements it with `MDBAPIClient`.
- `MDBTMDBEndpoints` builds every TMDB path and query. The service only fetches and parses.
- `MDBMoviePager` holds the shared paging rules for search, lists and genres: next page, dedupe by id and ignoring stale responses.
- `MDBFavoritesStore` is a protocol with a `favorites` observable. `MDBCoreDataFavoritesStore` implements it.
- `MDBPreferences` keeps region and language in `NSUserDefaults` and publishes a `current` snapshot. Home and Explore reload when it changes.

**Composition root**
- `MDBAppDependencies` creates the API client, services, Core Data stack and MetricKit subscriber once at launch.
- The coordinators receive it and hand pieces to the view models.
- Nothing calls a shared singleton, apart from Apple APIs that only exist as singletons.

## A request, end to end

1. `MDBHomeViewController` subscribes to `viewModel.state` and calls `[viewModel loadIfNeeded]`.
2. `MDBHomeViewModel` asks its `MDBMovieListProviding` service for four lists in parallel and sends a loading state.
3. `MDBTMDBMovieService` gets an `MDBEndpoint` from `MDBTMDBEndpoints` and calls `MDBAPIClient`.
4. The client builds the URL with sorted query items and adds `Authorization: Bearer <token>`. It starts an `os_signpost` interval and runs an `NSURLSession` task.
5. The JSON is parsed into models off the main thread. Every field goes through `NSDictionary+MDBSafeJSON`, which checks the type.
6. The client records the request in `MDBNetworkActivityLog` and calls the completion on the main queue.
7. The view model combines the lists with the genre names, turns them into `MDBMovieCellModel` objects (display-ready strings and image URLs) and sends a loaded state.
8. The subscription in the view controller calls `render:`.

## Memory and threading rules

- Every header uses `NS_ASSUME_NONNULL_BEGIN/END`, and anything that can be nil is marked `nullable`.
- `copy` for `NSString`, arrays and blocks. `weak` for delegates and parent coordinators.
- A block that outlives the call captures `__weak typeof(self) weakSelf` and turns it back into a strong reference before using it twice. `CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK` catches mistakes.
- Subscriptions live in a dispose bag owned by the subscriber, so they end when it is released. A derived observable holds its source, never the other way round.
- Models are immutable. A failable `initWithJSON:` returns nil when a required field is missing or has the wrong type.
- UI work happens on the main thread. The API client always calls back on the main queue, and `MDBAssertMainThread()` guards the Core Data reads.
- Core Data writes happen on a fresh background context. Reads use `viewContext`.
- Warnings are errors in the app target. The clang static analyzer runs on every Debug build.
- `MDBCoordinatorAndLeakTests testScreensAreReleased` loads every screen, drops it and fails if anything keeps it alive.

## Why not Clean Architecture with use cases

The reference projects use repositories and use cases that mostly pass calls straight through.
In an app this size that adds files without adding decisions, so services talk to the API client directly and the view model owns the screen logic.
If a feature grows real business rules, adding a use case between the view model and the service is a local change.

## Generated project

The Xcode project is generated from `project.yml` with XcodeGen, and CocoaPods adds the workspace.
Build settings live in `Configs/*.xcconfig` so they are easy to diff. See `docs/SECRETS.md` for how the token gets from `Secrets.xcconfig` into the app.
