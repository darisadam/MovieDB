# Contributing

Thanks for taking a look. The `objc` and `main` branches are protected, so changes go through pull requests.

## Workflow

1. **Fork** this repository to your own account.
2. Clone your fork and run `./Scripts/bootstrap.sh`.
3. Create a branch from `objc`: `git checkout -b fix/search-paging`.
4. Make your change, add or update tests, and run them.
5. Push to your fork and open a pull request against `darisadam/MovieDB:objc`.

A pull request needs one approving review and a green CI run before it can be merged.

## Before you open the PR

- [ ] `./Scripts/ci-test.sh` passes. Use `--all` to run on every installed iOS runtime.
- [ ] `./Scripts/format.sh --check` passes. CI runs the same check.
- [ ] No new compiler or analyzer warnings. Warnings are errors in the app target.
- [ ] `Scripts/check-secrets.sh --all` passes and no token is in the diff.
- [ ] New headers use `NS_ASSUME_NONNULL_BEGIN/END` and mark nullable values.
- [ ] Blocks that outlive the call use `weakSelf`. Subscriptions go into a dispose bag.
- [ ] UI text and comments read like a person wrote them. Keep them short and plain.

## Code style

- Objective-C, programmatic UIKit, no storyboards or xibs.
- Classes start with `MDB`. One class per file, unless a small private helper only that file uses.
- 2 spaces, no tabs, 130 columns. Run `./Scripts/format.sh` to apply `.clang-format` to every source file.
- Comments explain why, not what. Skip comments the code already says.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org): `feat(explore): add sort chips`, `fix(detail): stop trailer audio on close`.

## Adding a screen

1. Make a folder under `MovieDB/Features/<Name>/`.
2. Add `MDB<Name>ViewModel` with no UIKit, the service roles it needs injected in `init`, and a `state` observable of `MDBScreenState`.
3. Add `MDB<Name>ViewController` with `initWithViewModel:`, a subscription in `viewDidLoad`, a `render:` method and a delegate protocol for navigation.
4. Teach a coordinator to build and push it. `MDBMovieFlowCoordinator` is the place for screens every tab can reach.
5. Add tests for the view model with `MDBStubMovieService`, and add the screen to `testScreensAreReleased`.
6. Run `xcodegen generate` so the new files show up in Xcode.
