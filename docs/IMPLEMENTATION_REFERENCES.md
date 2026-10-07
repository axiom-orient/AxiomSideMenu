# Drawer interaction references

Reviewed on 2026-10-07 for the corrected AxiomSideMenu interaction contract. These are source references, not package dependencies. No third-party implementation was copied. Builds of these projects were not run.

## SlideMenu

Commit: `649dd3493882f1dd6b2e82ee5463bcb04e7accf6`.

The [gesture implementation](https://github.com/matteozappia/SlideMenu/blob/649dd3493882f1dd6b2e82ee5463bcb04e7accf6/Sources/SlideMenu/Core/SlideMenu.swift#L132-L177) captures the initial state, locks the drag axis, and derives the displayed offset from actual translation. It also incorporates predicted motion into its release decision. The direct tracking and bounded offset are useful references; the prediction shortcut does not satisfy the requested strict midpoint rule. Its state is owned inside the container, whereas AxiomSideMenu keeps the app's binding authoritative.

The [manifest](https://github.com/matteozappia/SlideMenu/blob/649dd3493882f1dd6b2e82ee5463bcb04e7accf6/Package.swift) requires Swift tools 6.3. This is not a drop-in dependency for a tools 6.0 package. [License: MIT](https://github.com/matteozappia/SlideMenu/blob/649dd3493882f1dd6b2e82ee5463bcb04e7accf6/LICENSE).

## ZSideMenu

Commit: `b62ecc9dead0b5c492b91a5a6827a28c12452958`.

Its [presentation logic](https://github.com/xzebra/ZSideMenu/blob/b62ecc9dead0b5c492b91a5a6827a28c12452958/Sources/ZSideMenu/ZSideMenuView.swift#L115-L150) clamps translation divided by drawer width into a normalized range. A velocity shortcut can finish a drag below the distance threshold. Its [recognizer adapter](https://github.com/xzebra/ZSideMenu/blob/b62ecc9dead0b5c492b91a5a6827a28c12452958/Sources/ZSideMenu/SidebarGestureView.swift#L104-L130) forwards cancellation through the same end path. The normalized range is a useful reference; AxiomSideMenu needs distinct cancellation and distance-only release decisions.

The [manifest](https://github.com/xzebra/ZSideMenu/blob/b62ecc9dead0b5c492b91a5a6827a28c12452958/Package.swift) uses Swift tools 6.0 and UIKit-backed iOS/Catalyst targets. It does not provide a native macOS target. [License: MIT](https://github.com/xzebra/ZSideMenu/blob/b62ecc9dead0b5c492b91a5a6827a28c12452958/LICENSE).

## SideMenu

Commit: `8bd4fd128923cf5494fa726839af8afe12908ad9`.

The [interaction controller](https://github.com/jonkykong/SideMenu/blob/8bd4fd128923cf5494fa726839af8afe12908ad9/Pod/Classes/SideMenuInteractionController.swift) separates update, finish, and cancel, rejects updates after termination, and cancels on background entry. These lifecycle boundaries inform cancellation handling. It is a UIKit controller library, rather than a SwiftUI component. Its [manifest](https://github.com/jonkykong/SideMenu/blob/8bd4fd128923cf5494fa726839af8afe12908ad9/Package.swift) declares Swift 4.2/5 language versions. [License: MIT](https://github.com/jonkykong/SideMenu/blob/8bd4fd128923cf5494fa726839af8afe12908ad9/LICENSE).

## Applied contract

- Direct tracking uses the captured displayed position plus current physical translation, bounded to fully closed and fully open.
- Release uses the final visible position: above half opens, below half closes, exactly half preserves the gesture's initial committed state. Prediction, speed, and peak displacement do not override this rule.
- Cancellation restores the committed state; app actions and changed layout invalidate stale commits.
- Background painting and safe content layout are separate. A background may extend through the status and home-indicator areas; controls remain inside the safe area.
- Logical edge selection is converted into the physical direction for both LTR and RTL layouts.

The references do not certify AxiomSideMenu behavior. Its own build, tests, real frame observations, and runtime checks provide that evidence.

## Safe content and custom backgrounds (0.1.2)

Apple's [WWDC21 safe-area explanation](https://developer.apple.com/videos/play/wwdc2021/10021/) distinguishes content that avoids system chrome from backgrounds that extend through it. Its examples apply safe-area expansion to the background independently of foreground controls.

[`GeometryProxy.safeAreaInsets`](https://developer.apple.com/documentation/swiftui/geometryproxy/safeareainsets) describes the current container's insets, rather than a universal status-bar or navigation-bar height. [`ignoresSafeArea`](https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:)) expands the region proposed to a view. These contracts guide the separate full-panel background geometry and the safe content frame.

Additional navigation-bar reservation is explicit and uses an app-measured height. The library does not query a global window, assume a fixed bar height, or compensate for an ancestor that has already discarded safe-area information. Runtime image-band and content-frame tests qualify the implementation.
