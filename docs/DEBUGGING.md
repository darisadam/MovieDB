# Debugging

Things built into the app to make bugs quicker to find.

## Logs

`MDBLog` wraps `os_log`. Use the macros, they add the file name and line for you.

```objc
MDBLogDebug(MDBLogCategoryNetwork, @"GET %@", url);      // Debug builds only
MDBLogInfo(MDBLogCategoryUI, @"Home loaded %lu sections", count);
MDBLogError(MDBLogCategoryPersistence, @"Save failed: %@", error);
MDBLogFault(MDBLogCategoryUI, @"This should never happen");
```

- **Categories:** `app`, `network`, `ui`, `persistence`, `coordinator`, `metrics`.
- **Console.app:** filter with `subsystem:com.darisadam.MovieDB`, and add `category:network` to narrow it down.
- **Debug builds** print the message in full. Release builds mark it private, so user data stays out of sysdiagnose.
- **Every request** logs a one line summary like `200 GET /3/movie/popular?page=1 182 ms 12.4 KB`. In Debug it also logs a cURL command with the token redacted, so you can replay a call in Terminal.

## Signposts

`MDBSignpost` adds intervals for every network request and for the first load of each screen (Home, Explore, Movie Detail, Person).

1. Product > Profile (Cmd+I).
2. Pick the **Time Profiler** or **Blank** template, then add the **Points of Interest** instrument.
3. Record and use the app. Each request shows its path and status, each screen shows how long it took to show content.

## MetricKit

`MDBMetricsSubscriber` receives launch time, hang, CPU, disk write and crash reports from MetricKit.
- It logs a summary under the `metrics` category and saves the full JSON to `Library/Caches/MetricKit`.
- Payloads arrive about once a day on a real device and never in the simulator.
- On a device you can force one with Xcode's **Debug > Simulate MetricKit Payloads**.
- The debug menu can share the saved files.

## Debug menu

Shake the device, or press **Ctrl+Cmd+Z** in the simulator, in a Debug build. You get:

- version, configuration (whether a token is set, never the token itself) and the coordinator tree
- a **Simulate offline** switch that makes every API call fail as if there were no network
- the last 100 requests, and copy the last one as cURL
- the last 300 log lines and a minimum log level switch
- saved MetricKit payloads
- **FLEX**, to inspect views, the network, the file system and `NSUserDefaults` live
- clear the image cache, delete all favorites

None of this is compiled into Release builds.

## LLDB

The `MovieDB` scheme loads `Scripts/lldb/MovieDB.lldbinit`. Pause the app and type:

| Command | What it prints or does |
|---|---|
| `mdb_vc` | view controller tree, the visible one is marked |
| `mdb_coords` | coordinator tree |
| `mdb_net` | recent requests with status, time and size |
| `mdb_curl` | the last request as a cURL command |
| `mdb_favs` | favorites saved in Core Data |
| `mdb_config` | token present or missing, region, language, offline mode |
| `mdb_logs` | recent log lines |
| `mdb_offline_on` / `mdb_offline_off` | toggle the fake offline mode |
| `mdb_log_level 2` | only errors and faults from now on (0 debug, 1 info, 2 error, 3 fault) |
| `mdb_break_on_fault` | break whenever `MDBLogFault` runs |
| `mdb_flush` | redraw after changing a view from the console |

If the aliases don't show up, check Edit Scheme > Run > Info > LLDB Init File. Xcode only reads it when a debug session starts.

## Useful breakpoints

- **Symbolic `MDBLogFaultHook`:** stops on every fault. `mdb_break_on_fault` adds it for you.
- **Symbolic `UIViewAlertForUnsatisfiableConstraints`:** stops on Auto Layout conflicts.
- **Exception breakpoint for Objective-C:** stops where the exception is thrown, not where it crashes.

## Sanitizers and checkers

The scheme runs with **Address Sanitizer** and the **Main Thread Checker** on, and stops on main thread issues.

- **Data races:** turn on **Thread Sanitizer** in Edit Scheme > Run > Diagnostics. It can't run together with Address Sanitizer.
- **Over-released objects:** turn on **Zombie Objects**. Turn Address Sanitizer off first.
- **Static analyzer:** runs on every Debug build. For a deeper pass, use Product > Analyze (Shift+Cmd+B).
- **Leaks:** for the full picture, run the **Leaks** instrument or use the **Debug Memory Graph** button while the app is paused. The view model release test in `MDBViewModelTests` catches the common block retain cycle.
