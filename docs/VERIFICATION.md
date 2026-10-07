# Verification — 0.1.1

Date: 2026-10-07. Target: the Swift package and checked-in iOS example after the interaction and safe-area corrections.

## Candidate identity

The immutable `0.1.1` tag identifies the qualified commit. The source, tests, and example project were frozen for the final gates with this SHA-256 fingerprint:

```text
f9ef7e49a7ef0a2d51f088f7615b2116f269ef4ba657aa3ddfdcdc99c8db22ca
```

Fingerprint input: sorted relative paths, each followed by a NUL byte, file bytes, and another NUL byte. Inputs are `Package.swift` and `.swift`, `.yml`, `.pbxproj`, `.xcscheme`, and `.xcworkspacedata` files under `Sources`, `Tests`, and `Examples`. Documentation and generated output are excluded.

## Executed gates

Toolchain: Xcode 27.0 (27A266a), Apple Swift 6.4 in Swift 6 language mode, macOS 27.0.1, iOS 27.0 SDK.

| Gate | Result | Evidence retained locally |
| --- | --- | --- |
| macOS release package tests | PASS: 28 tests in 3 suites | `v011-qualified-unit.log`, exit 0 |
| iOS 26.5, iPhone 17 Pro Max | PASS: 21/21 UI scenarios, exit 0 | `v011-qualified-ios26.xcresult` and `.log` |
| iOS 27.0, iPhone 18 Pro | PASS: 21/21 UI scenarios, exit 0 | `v011-qualified-ios27.xcresult` and `.log` |
| iOS device SDK release compile | PASS | `v011-qualified-ios-device.log`, exit 0 |
| Mac Catalyst example build | PASS | `v011-qualified-catalyst.log`, `BUILD SUCCEEDED`, exit 0 |
| Strict Swift format lint | PASS | `v011-qualified-lint.log`, exit 0 |
| Fresh separate local consumer | PASS | `v011-qualified-local-consumer.log`, exit 0 |
| Whitespace and package metadata | PASS | `git diff --check`, `v011-package.json` |

All evidence names above refer to files under the local QA directory, not files shipped inside the package. Both final UI bundles report exactly 21 passing tests, zero failures, zero skips, zero expected failures, and no runtime warnings. The consumer compiles both the original modifier and the new `background:` overload, executes an asynchronous main-actor close command, and checks that the app-owned state becomes false. This consumer check does not claim to render a desktop window or invoke an AI provider.

Catalyst emits linker search-path warnings for the installed Metal toolchain and an App Intents metadata-extraction warning because the example has no App Intents dependency. The build succeeds; these environment warnings are retained in the log. No production recovery path masks them.

## Runtime requirements

The final suite contains 21 real iOS UI scenarios on each runtime. Tests operate the actual example and library, without replacing the drawer with mocks.

| Coverage | Observed contract |
| --- | --- |
| Normal mode without diagnostics | Button opening, menu-button closing, edge opening and outward closing |
| Four midpoint scenarios | LTR leading/trailing and RTL leading/trailing; 100-point fast drags rejected, exact 140-point drags retain the starting state, 170-point drags commit, for a 280-point panel, in both opening and closing directions |
| Native frame observations | The actual CALayer presentation frame moves while the opening binding is still false; button opening and closing have intermediate positions and settle at their endpoints |
| Physical edge and image checks | Every sampled panel X stays within the selected physical edge's closed-to-open interval; a held halfway panel is rendered on that edge, and pixels on the opposite side show the dimmed primary area without a white gap |
| Closing animation regrab | A visible panel can be grabbed beyond the 28-point opening region while the committed binding is already false; real frames show outward travel followed by inward reversal without a frame jump above the test bound |
| Three safe-area scenarios | NavigationStack host, plain host, and short intrinsic menu: title starts at the actual window top safe inset plus 16-point app spacing; the full-height footer stays above the bottom safe inset; magenta panel fill covers status and home-indicator bands |
| Button/edge/scrim flow | Open, scroll, outside-tap close, edge reopen and close again |
| Closed edge button and transparent host | Ordinary taps reach native controls; a transparent root accepts edge opening and remains usable after dismissal |
| Zero width | Caller intent is retained without an invisible modal or blocked primary controls |
| Three directional flows | LTR trailing, RTL leading and RTL trailing open from the expected side, close outward, reopen and close by outside tap |
| Short/long drag flow | Short drags return to the original state; long outward drags close; blank panel taps do not dismiss |
| System interruption | A native sheet interrupts a held edge drag; after dismissal, main controls remain usable |
| External state changes | App-owned binding changes during a held drag remain authoritative; a stale gesture release cannot undo them |
| Modal interaction and recovery | Actual coordinate taps cannot invoke underlying primary controls while open; callback counters work before and after dismissal; the labeled Close menu control dismisses |

Native measurements use the real view's presentation layer converted into window coordinates and the real window safe-area insets. Missing measurement layers count as unavailable instead of substituting computed drawer progress. Held-frame screenshots use the real window image and actual image pixels. UIKit is used only by this example's diagnostic probes; the library remains SwiftUI-only.

The binding owns committed state; the library owns transient displayed position. Release above half-visible opens, below half-visible closes, and exactly half preserves the state captured at recognition. Velocity, prediction and peak excursion cannot override this rule. Pure tests additionally cover clamping, reversal, cancellation snapshots, invalidation generations, regrab positioning, stale completion rejection, logical/physical direction separation, and width edge cases.

## Refactor and repair loop

The original public modifier is preserved. Public API, pure interaction/geometry rules, and SwiftUI presentation remain separate. The new ShapeStyle overload paints the entire panel; menu controls use the host's offered safe content region without adding its safe insets twice. Short content is aligned to the top. The menu stays mounted during a drag or settling motion and is removed once fully closed.

Open-source principles and pinned revisions are documented in [implementation references](IMPLEMENTATION_REFERENCES.md). No third-party source or dependency was added.

Actual failures drove repairs to opening progress, recognition/reset ordering, closing-animation hit admission, duplicate safe-area padding, intrinsic-content alignment, and RTL transforms. An earlier full UI run passed a weaker position assertion but did not prove the partial RTL panel was on the right edge. A native frame/video inspection exposed a double mirroring of the offset. The corrected implementation uses logical edges for SwiftUI presentation and physical direction for gestures. Final physical-frame intervals and held-image pixel assertions catch that defect. Earlier full-suite results were discarded; only the final frozen fingerprint qualifies this release.

Fresh derived-data directories were used after an earlier run unexpectedly executed an old test body. Requested test counts are checked against the final xcresult summary. Failed or unfinished result bundles are not counted as passing evidence.

### Automation metadata discrepancy — [UNKNOWN]

Earlier iOS automation reported an underlying primary button as hittable while the menu was open, or supplied an invalid automatic edge-button hit point after a transition. The cause remains unknown. Regression guards send actual taps to the valid recorded control position and check unconditional callback counters. This proves pointer blocking and recovery; it does not certify VoiceOver focus behavior or attribute the metadata discrepancy to an SDK defect.

## Reproduction

From the repository root:

```sh
swift test -c release
swift format lint --strict --recursive Package.swift Sources Tests Examples/iOSDemo/Sources Examples/iOSDemo/UITests
swift package dump-package
git diff --check
```

Use either existing simulator: iOS 26.5 / iPhone 17 Pro Max (`B462783D-86CD-46ED-8C12-E147F20A65C1`) or iOS 27.0 / iPhone 18 Pro (`6F7E3B30-7343-4290-8F67-399ED0A20EBC`). Set the following variables to the device ID and new unused evidence paths:

```sh
xcodebuild test \
  -project Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj \
  -scheme AxiomSideMenuDemo \
  -destination "platform=iOS Simulator,id=$SIDEMENU_SIMULATOR_ID" \
  -derivedDataPath "$SIDEMENU_DERIVED_DATA" \
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

The device SDK gate uses `swift build -c release --triple arm64-apple-ios17.0`, the installed iPhoneOS SDK path, and a separate scratch directory. It compiles the library and does not launch a physical device. A fresh external Swift 6 consumer imports the product through a path dependency and calls both public API forms.

## Limits and release scope

| Item | Status and reason |
| --- | --- |
| Exact Swift 6.0 compiler | NOT_RUN: available compiler is Swift 6.4; manifest and language mode require Swift 6 |
| Minimum iOS 17/macOS 14/Catalyst 17 runtime | NOT_RUN: minimum deployment targets compile with installed SDKs; older runtimes were not available or installed |
| macOS and Catalyst GUI interaction | NOT_RUN: package tests and Catalyst build passed; desktop windows, pointer and keyboard paths were not exercised |
| Physical device, frame timing and performance traces | NOT_RUN: native simulator position/pixel observations prove functional motion; they do not certify physical-device smoothness or frame performance |
| VoiceOver and system Reduce Motion | NOT_RUN: dismiss/escape actions and Reduce Motion handling are implemented; assistive-technology flows and global settings were not exercised |
| Vertical drawers | OUT_OF_SCOPE: the two logical horizontal edges are supported |

Manual publication readback and a fresh remote consumer pinned with `exact: "0.1.1"` are postpublication checks recorded in the GitHub release notes. Published tags are immutable. Pin a tested version and restore the previous requirement if a later upgrade fails.
