# Changelog

## 0.1.3 — 2026-10-08

- Added the SideMenu root container with main/menu/background closures and the same app-owned binding.
- Established a complete root canvas for intrinsic main content, while keeping system-safe foreground layout separate from the panel background.
- Preserved all existing modifier signatures and canonical gesture/state ownership.
- Added root, intrinsic-content, navigation, and horizontal-safe-area regressions.

## 0.1.2 — 2026-10-07

- Added a separate View background closure for panel-wide image and custom backgrounds. The library sizes and clips them through the status and home-indicator bands.
- Added managed contentInsets for optional space inside the safe content region, without shrinking the background.
- Preserved both existing public modifier signatures and gesture behavior.
- Documented root attachment, measured navigation-bar reservations, and removal of 0.1.0 negative-inset workarounds.

## 0.1.1 — 2026-10-07

- Opening and closing drags now directly track the panel's actual position.
- Release uses the final visible midpoint. Exact halfway retains the starting committed state; velocity and prediction do not bypass the rule.
- Button and command changes settle from the current displayed position. Interrupted motion can be grabbed and reversed.
- Panel content is aligned to the top of the offered safe region without duplicate safe-area padding.
- Added a `background:` ShapeStyle overload for the whole panel, including the status and home-indicator bands. The original API is preserved.
- Added native frame, exact safe-area, screenshot-pixel, and normal-mode regression checks.

## 0.1.0 — 2026-10-07

- Initial Swift 6 SwiftUI package with no external dependencies.
- App-owned binding for button, command, or agent-action control.
- Leading and trailing drawers, including right-to-left layouts.
- Edge swipe opening, outward drag closing, and outside-tap dismissal.
- Cancellation and external state changes preserve the app's committed state.
- Safe-area layout and accessible dismiss actions.
- Runnable iOS example and regression tests.
