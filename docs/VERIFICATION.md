# Verification — 0.1.3

**Qualification: PASS for the package and example; manual publication is a separate action.** See [the Korean usage guide](USAGE_KO.md) for the APIs and consumer responsibilities.

Date: 2026-10-07. Target: the Swift package and checked-in iOS example after adding the root container and physical safe-area layout.

## Candidate identity

The `0.1.3` publication identifies the qualified commit. The final source, tests and example project fingerprint is:

```text
c21b7c79ef58b89825320827817563ce75f733983f82cbcd6d77a14af5314ad0
```

Fingerprint input: sorted relative paths, each followed by a NUL byte, file bytes, and another NUL byte. Inputs are `Package.swift` and `.swift`, `.yml`, `.pbxproj`, `.xcscheme`, and `.xcworkspacedata` files under `Sources`, `Tests`, and `Examples`. Documentation and generated output are excluded.

## Executed gates

Toolchain: Xcode 27.0 (27A266a), Apple Swift 6.4 in Swift 6 language mode, macOS 27.0.1, iOS 27.0 SDK.

| Gate | Result | Evidence retained locally |
| --- | --- | --- |
| macOS release package tests | PASS: 43 tests in 3 suites | `unit.log`, exit 0 |
| iOS 26.5, iPhone 17 Pro Max | PASS: 30 qualified scenarios, composite 25+4+1 | `full-ios26.xcresult`, `repaired-five-ios26.xcresult`, `contact-region-ios26.xcresult` |
| iOS 27.0, iPhone 18 Pro | PASS: 30 qualified scenarios, composite 25+4+1 | `full-ios27.xcresult`, `repaired-five-ios27.xcresult`, `contact-region-ios27.xcresult` |
| iOS device SDK release compile | PASS | `ios-device.log`, exit 0 |
| Mac Catalyst example build | PASS | `catalyst-final.log`, `BUILD SUCCEEDED`, exit 0 |
| Strict Swift format lint | PASS | `lint-final.log`, exit 0 |
| Fresh separate local consumer | PASS | `local-consumer.log`, exit 0 |
| Whitespace and package metadata | PASS | `git diff --check`, `package.json` |

Evidence is retained under the local `v013` QA directory, not shipped with the package. Final iOS qualification is composite: 25 unaffected passing scenarios from the complete original run, four midpoint scenarios from the input-repair run, and one contact-triggered regrab scenario from the final fixture, on each OS. These sets are disjoint and cover all 30 actual test IDs. `composite-qualification.json` records their source identities, bundles and individual results. Both final contact bundles have one PASS, zero failures/skips/expected failures, and native exit 0.

The original full runs each ended with 29 PASS and one failure, native exit 65. The input-repair iOS 27 run had four midpoint PASS and a regrab failure; the iOS 26 run had five PASS. Fixed-timer and whole-menu-contact failures remain preserved. None is described as a successful full run. No single current-fingerprint full30/30 result is claimed.

The qualification chain starts with fingerprint `db550073cc3d8f03ca972991dbca393e9265b5ec25e459dd1c1eb00da39f2afa`, followed by `5dc3de8bab1191bf636a9ba71f3bcd9dac36ec5bfd958891fbf2e7a8b7f7a7e5` and the final fingerprint above. Production Sources, Package.swift and unit tests remain byte-identical throughout. The midpoint held inputs increased from 0.3 to 0.8 seconds without changing their pixel, position or state criteria. The regrab test and its example-only contact flag changed; the other 29 flag-absent paths, common gesture/math, native pose probes and numeric guards are preserved. `input-repair-identity.json`, `contact-repair-identity.json` and `contact-region-repair-identity.json` retain actual backups, exact diffs and per-file hashes. Existing package tests, SDK compile and API-consumer results remain applicable to the unchanged implementation; the final example was rebuilt for Catalyst.

The separate Swift 6 consumer compiles both root initializers, the five preserved modifier signatures and method references, and image backgrounds. It executes an asynchronous main-actor close command and checks the app-owned state becomes false. This does not render a desktop window or invoke an AI provider.

Catalyst emits linker search-path warnings for the installed Metal toolchain and an App Intents metadata-extraction warning because the example has no App Intents dependency. The build succeeds; these environment warnings are retained in the log. No production recovery path masks them.

## Runtime requirements

The suite contains 30 real iOS UI scenarios on each runtime. Tests operate the actual example and library, without replacing the drawer with mocks.

| Coverage | Observed contract |
| --- | --- |
| Root container, intrinsic main content | A small main view receives a complete physical drawer/input canvas; the native menu frame, safe title/footer, buttons, edge opening, outward closing and callback recovery are observed |
| Root NavigationStack and raster background | Navigation is inside the root; a separate red/green/blue image covers the panel, with a measured 44-point extra content reservation and a safe footer |
| Four landscape root scenarios | LTR/RTL leading/trailing use a physical 280-point panel and the actual horizontal safe inset. Only the intersecting outer band reduces content width; panel, scrim pixels, short/long drags and recovery share the same origin |
| Normal mode without diagnostics | Button opening, menu-button closing, edge opening and outward closing |
| Four midpoint scenarios | LTR leading/trailing and RTL leading/trailing; 100-point fast drags rejected, exact 140-point drags retain the starting state, 170-point drags commit, for a 280-point panel, in both opening and closing directions |
| Native frame observations | The actual CALayer presentation frame moves while the opening binding is still false; button opening and closing have intermediate positions and settle at their endpoints |
| Physical edge and image checks | Every sampled panel X stays within the selected physical edge's closed-to-open interval; a held halfway panel is rendered on that edge, and pixels on the opposite side show the dimmed primary area without a white gap |
| Closing animation regrab | A visible panel can be grabbed beyond the 28-point opening region while the committed binding is already false; real frames show outward travel followed by inward reversal without a frame jump above the test bound |
| Three raster-image background scenarios | Actual opaque red/green/blue raster image through the separate background closure: default NavigationStack host, explicit extra top reservation of 44 points, and short plain menu. Pixel samples at the top, middle and bottom prove the image covers the panel; actual content Y is safeTop plus only the requested extra inset. The 44 points are a test input, not an assumed system-bar height |
| Three safe-area scenarios | NavigationStack host, plain host, and short intrinsic menu: title starts at the actual window top safe inset plus 16-point app spacing; the full-height footer stays above the bottom safe inset; magenta panel fill covers status and home-indicator bands |
| Button/edge/scrim flow | Open, scroll, outside-tap close, edge reopen and close again |
| Closed edge button and transparent host | Ordinary taps reach native controls; a transparent root accepts edge opening and remains usable after dismissal |
| Zero width | Caller intent is retained without an invisible modal or blocked primary controls |
| Three directional flows | LTR trailing, RTL leading and RTL trailing open from the expected side, close outward, reopen and close by outside tap |
| Short/long drag flow | Short drags return to the original state; long outward drags close; blank panel taps do not dismiss |
| System interruption | A native sheet interrupts a held edge drag; after dismissal, main controls remain usable |
| External state changes | App-owned binding changes during a held drag remain authoritative; a stale gesture release cannot undo them |
| Modal interaction and recovery | Actual coordinate taps cannot invoke underlying primary controls while open; callback counters work before and after dismissal; the labeled Close menu control dismisses |

Landscape pixel assertions use original full-screen PNGs and their actual EXIF orientation. The native app frame must match the oriented image geometry and scale before sampling. App-only landscape captures with inconsistent crop/orientation geometry are retained as failing evidence. They are not edited or substituted; no computed frame or expected color is used as a fallback.

Native measurements use the real view's presentation layer converted into window coordinates and the real window safe-area insets. Missing measurement layers count as unavailable instead of substituting computed drawer progress. Held-frame screenshots use the real window image and actual image pixels. UIKit is used only by this example's diagnostic probes; the library remains SwiftUI-only.

The binding owns committed state; the library owns transient displayed position. Release above half-visible opens, below half-visible closes, and exactly half preserves the state captured at recognition. Velocity, prediction and peak excursion cannot override this rule. Pure tests additionally cover clamping, reversal, cancellation snapshots, invalidation generations, regrab positioning, stale completion rejection, logical/physical direction separation, and width edge cases.

## Refactor and repair loop

The additive `SideMenu` root container fills the offered canvas and restores container-safe foreground guides from the outer-minus-inner inset difference. It intersects horizontal safety with the physical panel, then bounds optional extra reservations inside the remaining content region. Background, scrim and edge input use the same full canvas. All five modifier signatures are preserved, and gestures/animation remain in one canonical modifier.

A landscape regression initially exposed a full 280-point content width where a 62-point outer safe band required 218 points. Actual native frames and all four landscape scenarios verify the correction. Ancestor clipping and already discarded safe-area information cannot be recovered by a local root container; no global window lookup or guessed navigation-bar height is added.

Both original public modifier signatures and bound method references are preserved. Additive overloads reserve contentInsets inside the safe content region and provide a separate background View closure. The background receives its own full-height proposal, is clipped, and excludes input/accessibility; an independent clear shield retains blank-panel tap absorption. Resolved finite insets are shared by rendering and layout invalidation; invalid values resolve to zero and combined reservations are bounded by the safe content size.

Version 0.1.0 repeated safe-area padding. Consumers upgrading from that version must remove any negative-inset compensation and keep their ordinary design spacing. The background closure lets image fills cover the panel without moving controls into the status area. A measured top reservation is optional; no global window lookup or fixed navigation-bar height is used.

The original public modifier is preserved. Public API, pure interaction/geometry rules, and SwiftUI presentation remain separate. The new ShapeStyle overload paints the entire panel; menu controls use the host's offered safe content region without adding its safe insets twice. Short content is aligned to the top. The menu stays mounted during a drag or settling motion and is removed once fully closed.

Open-source principles and pinned revisions are documented in [implementation references](IMPLEMENTATION_REFERENCES.md). No third-party source or dependency was added.

Actual failures drove repairs to opening progress, recognition/reset ordering, closing-animation hit admission, duplicate safe-area padding, intrinsic-content alignment, and RTL transforms. An earlier full UI run passed a weaker position assertion but did not prove the partial RTL panel was on the right edge. A native frame/video inspection exposed a double mirroring of the offset. The corrected implementation uses logical edges for SwiftUI presentation and physical direction for gestures. Final physical-frame intervals and held-image pixel assertions catch that defect. These historical intermediate results are not qualification for the new root. The composite evidence and exact input-repair identity described above qualify this release.

New image tests first passed as a focused three-test run on iOS 26.5. It directly observed a 62-point safe top, default native content Y=62, and explicit reservation Y=106; top/middle/bottom image pixels and safe footer assertions passed. These focused results do not replace the full final suite.

Fresh derived-data directories were used after an earlier run unexpectedly executed an old test body. Requested test counts are checked against the final xcresult summary. Failed or unfinished result bundles are not counted as passing evidence.

### Input and observation repair

Fixed three-second scheduling and 2.73/2.83-second presses were sensitive to automation latency. One run reversed after only 17.67 points of closing travel, below the unchanged 20-point requirement; another started moving after the panel had already closed. These failed attempts do not qualify regrab.

The final example-only `--close-on-contact` fixture arms a close action. A separate actual 44×44 contact region at X=60, outside the 28-point opening zone, detects real finger contact and changes only the app-owned binding to false. The test reads the region's actual accessibility frame before arming, verifies live arm=1/contactCount=0/intent=1, holds for 80ms and drags inward 170 points. It then verifies actual callbackCount=1/arm=0 and the same native outward travel, reversal >=20, first-reversal membership, frame jump <80 and final open state. Position, recognition snapshots, final binding=true and animation duration are never forced by the fixture. The normal example has no additional contact gesture.

An intermediate whole-menu contact handler failed; its overlap with the arming button was a suspected cause, not a proven runtime diagnosis. Restricting contact to a distinct region makes the causal sequence observable. Final native results pass on both OS versions; the original failures remain retained.

Exact-half captures retain the actual five-stable-frame requirement and real image pixels. The failed iOS 27 trace also records external Caseboard foreground activity. Final qualification operations use an exclusive exact-device lease and serial native tests. No diagnostic failure or unsupported screenshot geometry is silently replaced.

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

The device SDK gate uses `swift build -c release --triple arm64-apple-ios17.0`, the installed iPhoneOS SDK path, and a separate scratch directory. It compiles the library and does not launch a physical device. A fresh external Swift 6 consumer imports the product through a path dependency, compiles all public API families, and executes the app-owned asynchronous close function.

## Limits and release scope

| Item | Status and reason |
| --- | --- |
| Exact Swift 6.0 compiler | NOT_RUN: available compiler is Swift 6.4; manifest and language mode require Swift 6 |
| Minimum iOS 17/macOS 14/Catalyst 17 runtime | NOT_RUN: minimum deployment targets compile with installed SDKs; older runtimes were not available or installed |
| Actual keyboard appearance/change in the root container | NOT_RUN: residual keyboard-guide calculations have pure test coverage; no native keyboard-transition scenario was executed |
| macOS and Catalyst GUI interaction | NOT_RUN: package tests and Catalyst build passed; desktop windows, pointer and keyboard paths were not exercised |
| Physical device, frame timing and performance traces | NOT_RUN: native simulator position/pixel observations prove functional motion; they do not certify physical-device smoothness or frame performance |
| VoiceOver and system Reduce Motion | NOT_RUN: dismiss/escape actions and Reduce Motion handling are implemented; assistive-technology flows and global settings were not exercised |
| Vertical drawers | OUT_OF_SCOPE: the two logical horizontal edges are supported |

Manual publication readback and a fresh remote consumer pinned with `exact: "0.1.3"` are postpublication checks recorded in the GitHub release notes. Published tags are immutable. Pin a tested version and restore the previous requirement if a later upgrade fails.
