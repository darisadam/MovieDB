# MovieDB

A movie browser for iPhone, written in **Objective-C** with **programmatic UIKit** (no storyboards).
It uses [The Movie Database (TMDB)](https://www.themoviedb.org) for data and saves favorites on the device with Core Data.

This started as my iOS onboarding project at Nusantara Beta Studio. The `objc` branch is the full Objective-C version and the default branch of this repo. The older Swift version lives on `main`.

## What it does

- **Home** shows a Now Playing carousel plus Popular, Top Rated and Upcoming rows, each with a See All page.
- **Explore** has trending movies, genre shortcuts and search with debounce and infinite scroll.
- **Movie detail** has the rating, runtime, genres, storyline, facts, cast, trailers and similar movies.
- **Person** pages show a short bio, Known For and the filmography.
- **Favorites** are stored locally with Core Data, work offline and support swipe to remove.
- **Menu** lets you browse by genre, pick the region and language sent to TMDB, clear favorites and read the About page.
- Loading skeletons, empty states, offline and error states with Retry, Dynamic Type and VoiceOver labels.

## Requirements

- Xcode 27 or newer. iOS 15.0 is the minimum target, because Xcode 27 can't build for anything older.
- [Homebrew](https://brew.sh), used to install XcodeGen, CocoaPods and gitleaks.
- A free TMDB account and its **API Read Access Token**, from [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).

## Getting started

```sh
git clone https://github.com/darisadam/MovieDB.git
cd MovieDB
./Scripts/bootstrap.sh
```

1. The script installs the tools, generates `MovieDB.xcodeproj` with XcodeGen, runs `pod install` and adds a pre-commit hook.
2. Open `Configs/Secrets.xcconfig`, which the script created, and paste your token after `TMDB_ACCESS_TOKEN = `.
3. Open **MovieDB.xcworkspace**, not the project file.
4. Pick an iPhone simulator and press Run.

Without a token the app still builds and runs. It shows a "TMDB token missing" screen instead of movies.

The Xcode project and workspace are generated, so they are not in git. Run `xcodegen generate && pod install` after you pull changes that touch `project.yml` or the `Podfile`.

## Tests

```sh
./Scripts/ci-test.sh          # newest iOS runtime
./Scripts/ci-test.sh --all    # one iPhone for every installed iOS runtime
./Scripts/format.sh --check   # the same style check CI runs
```

83 tests cover the observables, JSON parsing, endpoints, the API client with a stubbed URL protocol, paging, every view model, the Core Data store, coordinator navigation and leaks in every screen. They never call the real TMDB API.

## TestFlight

The bundle id is `com.adamappstudio.moviedb`. To ship a build:

1. Sign in to Xcode with the Apple ID of the team in `project.yml` (Settings > Accounts).
2. Make sure `Configs/Secrets.xcconfig` has a token. The script refuses to archive without one.
3. Run `./Scripts/release-testflight.sh`. It bumps the build number in `project.yml`, archives a Release build and uploads it with `Scripts/ExportOptions.plist`.

Commit the build number change afterwards. `--no-upload` archives and exports without uploading.

## Project layout

```
MovieDB/
  App/            launch, scene, dependency container, Info.plist, assets
  Coordinators/   navigation, one coordinator per tab plus shared movie flows
  Core/           observables, networking, Core Data, logging, signposts, MetricKit, debug tools
  Models/         immutable models parsed from TMDB JSON
  Services/       service protocols, TMDB endpoints and service, pager, favorites store protocol, preferences
  UIComponents/   cells and reusable views
  Features/       one folder per screen with its view controller and view model
MovieDBTests/     XCTest with JSON fixtures
Configs/          xcconfig files, Secrets.example.xcconfig
Scripts/          bootstrap, tests, format, release, secret check, git hooks, LLDB helpers
docs/             architecture, debugging, secrets, contributing
```

## Docs

- [Architecture](docs/ARCHITECTURE.md): MVVM with coordinators and how data flows through the app
- [Debugging](docs/DEBUGGING.md): logs, signposts, MetricKit, the shake menu, FLEX and LLDB aliases
- [Secrets](docs/SECRETS.md): how the TMDB token is kept out of git and how to rotate it
- [Contributing](docs/CONTRIBUTING.md): fork, branch and open a pull request

## Third-party code

| Library | Why | Builds |
|---|---|---|
| [SDWebImage](https://github.com/SDWebImage/SDWebImage) | image download with memory and disk cache | all |
| [FLEX](https://github.com/FLEXTool/FLEX) | in-app inspector for views, network and files | Debug only |

## Credits

- Movie data and images come from [TMDB](https://www.themoviedb.org). This product uses the TMDB API but is not endorsed or certified by TMDB.
- The design is based on the Nusantara Beta Studio "MovieDB" onboarding project.
- Built by Adam Daris Ryadhi.

## License

MIT, see [LICENSE](LICENSE).
