# Verification — 0.1.0

Date: 2026-10-07. Target: the initial public Swift package and checked-in iOS example.

## Candidate identity

The `0.1.0` tag identifies the final candidate commit. Builds and tests used the same source, tests, and project configuration, frozen with this SHA-256 fingerprint:

```text
55b9ab0eb1e2d1187eccc944e1e4d92092caf47556a496e2be77ec5d4c6558ac
```

Fingerprint input: sorted relative paths, each followed by a NUL byte, file bytes, and another NUL byte. Inputs are `Package.swift` and `.swift`, `.yml`, `.pbxproj`, `.xcscheme`, and `.xcworkspacedata` files under `Sources`, `Tests`, and `Examples`. Documentation and generated build output are excluded.

## Executed gates

Toolchain: Xcode 27.0 (27A266a), Apple Swift 6.4 in Swift 6 language mode, macOS 27.0.1, iOS 27.0 SDK.

| Gate | Result | Evidence |
| --- | --- | --- |
| macOS release package tests | PASS: 12 tests in 3 suites | Swift Testing summary in `shipping-macos.log` |
| iOS 26.5, iPhone 17 Pro Max | PASS: 12/12 UI scenarios | `qualified-flow-ios26.xcresult`, test summary and process exit |
| iOS 27.0, iPhone 18 Pro | PASS: 12/12 UI scenarios | `qualified-flow-ios27.xcresult`, test summary and process exit |
| iOS device SDK release compile | PASS | `shipping-ios-device.log` |
| Mac Catalyst example build | PASS | `shipping-catalyst.log`, `BUILD SUCCEEDED` |
| Strict Swift format lint | PASS | `shipping-lint.log`, exit 0 |
| Separate local consumer | PASS | `shipping-local-consumer.log`; public import, trailing menu API, main-actor close action and resulting state |
| Whitespace and package metadata | PASS | `git diff --check`, `swift package dump-package` |

The xcresult bundles and full logs are retained locally. No tests are skipped or marked as expected failures in the passing UI runs. The tests launch the real example, operate its native controls, drag on screen, and query the resulting state. They do not replace the library with mocks.

## Runtime requirements

Each of these 12 scenarios is executed on both listed iOS runtimes:

| Scenario | What it checks |
| --- | --- |
| Button and edge opening | Open, scroll menu content, outside tap, reopen from the edge, close again |
| Closed edge button | Native button inside the 28-point admission region receives an ordinary tap exactly once |
| Transparent host | Open from a plain transparent screen, close with a menu button, use the edge button afterward |
| Zero width | Retain caller intent without mounting an invisible modal or blocking the main screen; external close clears intent |
| Safe area and menu button | Menu controls remain below the top safe area and can close the menu |
| LTR trailing | Right edge opening, outward drag closing, reopen and outside-tap closing |
| RTL leading | Same flow from the physical right edge |
| RTL trailing | Same flow from the physical left edge |
| Short and long drags | Reject short opening and closing drags, absorb blank panel taps, close with a long outward drag |
| System interruption | Present a native sheet during a held opening drag; dismiss and recover usable main controls |
| External state changes | App-owned open/close actions during a held drag remain authoritative; stale release does not undo them |
| Modal action blocking and recovery | App-owned callback counters prove that actual coordinate taps reach primary controls when closed, are blocked underneath the panel and outside scrim when open, and work after dismissal; the labeled dismiss control closes the menu |

Opening swipes commit on release. Closing progress follows the drag. The presentation binding is the committed source of truth. An app or agent action can use the same main-actor close function; the separate consumer executes that function and checks the resulting state. No AI provider or model integration is bundled or claimed as tested.

## Refactor and repair loop

The public modifier signature remains unchanged. The implementation now separates the public API, pure geometry/recognition rules, and SwiftUI presentation.

Actual UI failures drove repairs to cancellation reset, stale gesture commits after external changes, native child-button hit testing, RTL outside-area placement, transparent-host recovery, and explicit primary interaction isolation. Gesture, caller-state, native-control, and recovery regression assertions remain in place. Recognition metadata grants permission to commit; `GestureState` owns temporary progress and resets after interruption. The menu is mounted only while presented with a positive width; persistent selection and data belong outside it. The external-close fixture arms its three-second timer after observation, immediately before a 3.5-second held drag, so the measured state change occurs during the gesture.

### Automation metadata discrepancy — [UNKNOWN]

An earlier assertion required the covered primary button's `isHittable` value to be false. On iOS 27 with `NavigationStack`, it repeatedly remained true. A direct coordinate-tap probe then demonstrated that the actual primary action callback was blocked while the menu was open, and ran before and after dismissal on both runtimes. Counters increment unconditionally at callback entry; no fixture presentation guard suppresses them.

The regression guard now sends real taps and checks callback counts in the open-state scenarios. The dedicated modal scenario also exercises the outside scrim and checks recovery. This tests the pointer interaction contract directly instead of treating automation hit-point metadata as proof of an action. Apple describes [`isHittable`](https://developer.apple.com/documentation/xcuiautomation/xcuielement/ishittable) as hit-point availability and says covered elements should return false. The reason for the observed discrepancy remains [UNKNOWN]; it is not attributed to an SDK defect or treated as proof of VoiceOver focus isolation. An iOS 26 automatic edge-button tap also produced the invalid computed hit point `{-1,-1}` after an external transition. The recovery regression sends input to the valid position recorded before that transition and checks the same action count. The cause of this automation discrepancy remains [UNKNOWN]. Earlier failing runs are retained locally.

## Reproduction

From the repository root:

```sh
swift test -c release
swift format lint --strict --recursive Package.swift Sources Tests Examples/iOSDemo/Sources Examples/iOSDemo/UITests
swift package dump-package
git diff --check
```

For each existing simulator, set `SIDEMENU_SIMULATOR_ID` to its identifier and `SIDEMENU_RESULT_PATH` to a new, unused result-bundle path:

```sh
xcodebuild test \
  -project Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj \
  -scheme AxiomSideMenuDemo \
  -destination "platform=iOS Simulator,id=$SIDEMENU_SIMULATOR_ID" \
  -parallel-testing-enabled NO \
  -resultBundlePath "$SIDEMENU_RESULT_PATH" \
  CODE_SIGNING_ALLOWED=NO

xcrun xcresulttool get test-results summary --path "$SIDEMENU_RESULT_PATH"
```

```sh
xcodebuild build \
  -project Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj \
  -scheme AxiomSideMenuDemo \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  CODE_SIGNING_ALLOWED=NO
```

The device SDK gate used `swift build -c release --triple arm64-apple-ios17.0`, the installed iPhoneOS 27.0 SDK path, and a separate scratch directory. It compiles the real library; it does not launch a physical device.

## Limits and release scope

| Item | Status and reason |
| --- | --- |
| Exact Swift 6.0 compiler | NOT_RUN: available compiler is Swift 6.4; manifest and language mode require Swift 6 |
| Minimum iOS 17/macOS 14/Catalyst 17 runtime | NOT_RUN: minimum deployment targets compile with the installed SDKs; those older runtimes were not available or installed |
| macOS and Catalyst GUI interaction | NOT_RUN: macOS package tests and Catalyst build passed; their windows, pointer and keyboard paths were not exercised |
| Physical device, frame timing and performance traces | NOT_RUN: simulator correctness is the evidence; no performance or physical-device claim |
| VoiceOver and system Reduce Motion behavior | NOT_RUN: accessible dismiss/escape actions and Reduce Motion handling are implemented, but global accessibility settings and assistive-technology flows were not changed or exercised |
| Vertical drawers | OUT_OF_SCOPE: this release supports the two logical horizontal edges |

These limits are separate from the executed iOS correctness gates. Manual publication readback and a fresh remote consumer pinned to `0.1.0` are postpublication checks; their result belongs in the GitHub release notes. Pin a tested version and restore the previous requirement if a later upgrade fails. Published tags must not be moved.
