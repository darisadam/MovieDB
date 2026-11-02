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
- They set `viewModel.onChange` to a block that calls `render`, and `render` reads the view model and updates every view. There is one place where the screen gets drawn, so it is easy to reason about.

**View models** have no UIKit imports.
- They expose read-only state, an `MDBLoadState` (idle, loading, loaded, empty, failed) and an `onChange` block.
- Services come in through `init`, so tests can pass stubs.
- They cancel their requests in `dealloc`.

**Services**
- `MDBMovieService` is a protocol. `MDBTMDBMovieService` implements it with `MDBAPIClient`. The view models only see the protocol.
- `MDBFavoritesStore` is a protocol. `MDBCoreDataFavoritesStore` implements it.
- `MDBPreferences` keeps region and language in `NSUserDefaults` and posts a notification when they change. Home, Explore and Menu reload when that happens.

**Composition root**
- `MDBAppDependencies` creates the API client, services, Core Data stack and MetricKit subscriber once at launch.
- The coordinators receive it and hand pieces to the view models.
- Nothing calls a shared singleton, apart from Apple APIs that only exist as singletons.

## A request, end to end

1. `MDBHomeViewController` calls `[viewModel loadIfNeeded]`.
2. `MDBHomeViewModel` asks `id<MDBMovieService>` for four lists in parallel.
3. `MDBTMDBMovieService` builds an `MDBEndpoint` and calls `MDBAPIClient`.
4. The client builds the URL with sorted query items and adds `Authorization: Bearer <token>`. It starts an `os_signpost` interval and runs an `NSURLSession` task.
5. The JSON is parsed into models off the main thread. Every field goes through `NSDictionary+MDBSafeJSON`, which checks the type.
6. The client records the request in `MDBNetworkActivityLog` and calls the completion on the main queue.
7. The view model turns models into `MDBMovieCellModel` objects (display-ready strings and image URLs), updates its state and fires `onChange`.
8. The view controller renders.

## Memory and threading rules

- Every header uses `NS_ASSUME_NONNULL_BEGIN/END`, and anything that can be nil is marked `nullable`.
- `copy` for `NSString`, arrays and blocks. `weak` for delegates and parent coordinators.
- A block that outlives the call captures `__weak typeof(self) weakSelf` and turns it back into a strong reference before using it twice. `CLANG_WARN_OBJC_REPEATED_USE_OF_WEAK` catches mistakes.
- Notification observers are removed in `dealloc`.
- Models are immutable. A failable `initWithJSON:` returns nil when a required field is missing or has the wrong type.
- UI work happens on the main thread. The API client always calls back on the main queue, and `MDBAssertMainThread()` guards the Core Data reads.
- Core Data writes happen on a fresh background context. Reads use `viewContext`.
- Warnings are errors in the app target. The clang static analyzer runs on every Debug build.
- `MDBViewModelTests testViewModelsAreReleased` fails if a view model leaks through a block.

## Why not Clean Architecture with use cases

The reference projects use repositories and use cases that mostly pass calls straight through.
In an app this size that adds files without adding decisions, so services talk to the API client directly and the view model owns the screen logic.
If a feature grows real business rules, adding a use case between the view model and the service is a local change.

## Generated project

The Xcode project is generated from `project.yml` with XcodeGen, and CocoaPods adds the workspace.
Build settings live in `Configs/*.xcconfig` so they are easy to diff. See `docs/SECRETS.md` for how the token gets from `Secrets.xcconfig` into the app.
