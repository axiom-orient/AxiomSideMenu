# AxiomSideMenu

A small SwiftUI drawer with one app-owned presentation binding. No external dependencies. Swift 6 language mode; iOS 17+, macOS 14+, and Mac Catalyst 17+.

[한국어 사용법과 구현 기준](docs/USAGE_KO.md)

This README documents 0.1.3. Sumday intentionally remains pinned to 0.1.2. See the GitHub release page for publication status.

## Installation

In Xcode, add this package URL and select Exact Version **0.1.3**:

    https://github.com/axiom-orient/AxiomSideMenu.git

In a Swift package:

~~~swift
 dependencies: [
   .package(url: "https://github.com/axiom-orient/AxiomSideMenu.git", exact: "0.1.3")
 ],
 targets: [
   .target(
     name: "YourApp",
     dependencies: [.product(name: "AxiomSideMenu", package: "AxiomSideMenu")]
   )
 ]
~~~

For local development, use .package(path: "../AxiomSideMenu") or Xcode's Add Local option.

## Start with the root container

Put the main screen and menu in one root container. No safe-area calculations or negative padding are needed:

~~~swift
import AxiomSideMenu
import SwiftUI

struct AppScreen: View {
  @State private var isMenuOpen = false

  var body: some View {
    SideMenu(isPresented: $isMenuOpen) {
      NavigationStack {
        Button("Open menu") { isMenuOpen = true }
      }
    } menu: {
      VStack(alignment: .leading, spacing: 16) {
        Text("Menu")
        Button("Home") { isMenuOpen = false }
        Button("Settings") { isMenuOpen = false }
        Spacer()
      }
      .padding(16)
    }
  }
}
~~~

The container fills the root's visible canvas even when the main view is small. It owns the panel's physical bounds and safe foreground area. Menu backgrounds cover system safe-area bands; interactive content avoids those bands. Navigation belongs inside the main closure.

Use `edge: .trailing` for the opposite side. A custom image has its own closure:

~~~swift
SideMenu(isPresented: $isMenuOpen, edge: .trailing) {
  NavigationStack { MainScreen() }
} menu: {
  MenuScreen()
} background: {
  Image("SidebarPaper").resizable().scaledToFill()
}
~~~

The app owns menu items, routing and ordinary design spacing. A screen change or command closes the same app-owned binding. The library owns edge admission, drag progress, release thresholds, animation and modal input isolation.

### Existing modifier API

Existing `.sideMenu(isPresented:) { ... }` calls remain available. Use the modifier when you intentionally want a drawer bounded by a particular host view. Attach it outside NavigationStack to cover its bar. Its sizing follows that host's offered region; the root container is the default for a full-screen drawer.

## App commands and agent actions

Any app action can close the menu by setting its binding to false. Keep a shared presentation model on the main actor if an agent or tool handler needs to control it:

~~~swift
import Observation

@MainActor
@Observable
final class SidebarState {
  var isPresented = false

  func close() {
    isPresented = false
  }
}
~~~

Use `SideMenu(isPresented: $sidebar.isPresented)` at the root, or the existing modifier for a bounded host. An agent action running on another actor can call await sidebar.close(). Caller state changes supersede an in-flight drawer gesture. The app continues to own its routing and agent integration.

Use edge: .leading or edge: .trailing to select the logical horizontal edge. In a left-to-right layout these are the left and right sides respectively; right-to-left layouts reverse them.

## Behavior

- Your binding owns the committed open state. The menu does not own routing or selection.
- Swipe inward from the first 28 points of the chosen edge to open. Drag outward or tap the dimmed area to close. Buttons can change the binding directly.
- Both opening and closing drags move the panel with the finger. Release above half-visible to open, below half-visible to close. Exactly half preserves the gesture's starting committed state. A short fast flick does not bypass this distance rule. Rejected drags animate back to their resting state.
- Button and command changes animate from the current position toward the selected edge's open or closed endpoint. Temporary progress belongs to the library; the app binding changes only on a committed gesture or app action.
- Use edge: .trailing for the opposite logical edge. Both edges follow the host's layout direction.
- Width is capped at the host view's width. Negative or NaN widths produce zero width; positive infinity uses the available width. With resolved width zero, the host remains interactive and no menu is mounted; the caller retains its presentation intent.
- The overlay preserves the host view's layout. Attach it to the root view whose area should contain the drawer.
- Menu content is mounted during presentation, a drag preview, and settling. It is removed after settling fully closed. Keep persistent selection, routes, and data in the app's state outside the menu; local menu view state resets after full dismissal.
- The menu provides a labeled dismiss control and an accessibility escape action. Reduce Motion disables animated travel.

An edge-opening gesture shares the edge with native back navigation and horizontal content gestures. Place the drawer at your navigation root or use a different edge when that region belongs to another interaction.

## Background and content boundaries

For the modifier API, attach it to a full-height root **outside `NavigationStack`**. Its menu content starts at the top of that root's safe content region, below the status bar. The library does not add the system safe-area inset a second time. A short menu is aligned to the top.

The library owns the panel's content frame and background frame separately. Keep the menu header, scrollable list, footer and ordinary design spacing inside the menu closure. Supply a decorative image or custom background in the separate background closure:

~~~swift
mainContent
  .sideMenu(isPresented: $isMenuOpen, edge: .trailing) {
    VStack(spacing: 16) {
      Text("Menu")
      ScrollView {
        // Your menu items.
      }
      Button("Close") { isMenuOpen = false }
    }
    .padding(16)
  } background: {
    Image("SidebarPaper")
      .resizable()
      .scaledToFill()
  }
~~~

The library sizes and clips the background to the full panel, including the status-bar and home-indicator bands. Background views are decorative: their controls do not receive input or accessibility focus. The header and footer remain in the safe content region while the list scrolls.

For a color, gradient or material, the existing `background: ShapeStyle` overload remains available. The original modifier and default root container use the system background style.

On either API, `contentInsets` adds space **inside** the already safe content region. It defaults to zero for the background-view overload. To reserve a navigation bar or custom header, pass its measured height; do not add the status-bar inset again or assume a universal 44-point navigation bar:

~~~swift
mainContent
  .sideMenu(
    isPresented: $isMenuOpen,
    contentInsets: EdgeInsets(
      top: measuredNavigationBarHeight, leading: 0, bottom: 0, trailing: 0
    )
  ) {
    MenuContent()
  } background: {
    Image("SidebarPaper").resizable().scaledToFill()
  }
~~~

The modifier also accepts `contentInsets:` with the default fill or a ShapeStyle fill. Extra content insets do not shrink the background. Insets are finite, nonnegative reservations. Invalid values resolve to zero; combined reservations are bounded by the offered safe content size.

The advanced modifier uses its host's bounds and safe region. A modifier attached inside a navigation screen cannot cover an ancestor navigation bar. An ancestor that ignores safe areas also changes the region the modifier receives. Attach the drawer outside those scopes; the library does not query a global window or guess system-bar heights.

### Upgrading from 0.1.0

Version 0.1.0 added duplicate safe-area padding. If your app compensated with negative top/bottom padding, remove that compensation when upgrading. Keep ordinary design padding. Move an image background from the menu content into the separate background closure so its fill covers the entire panel.

Implementation references and their exact commits are recorded in [source research](docs/IMPLEMENTATION_REFERENCES.md).

## Example and verification

Open Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj. The checked-in Xcode project directly references this package; XcodeGen is needed only to regenerate it from project.yml.

See [verification evidence](docs/VERIFICATION.md) for the tested revision, commands, runtime scenarios, and platform limits. The minimum compiler and OS requirements are distinct from the toolchain and runtimes actually tested.

## Version pinning and recovery

Use .package(url: "https://github.com/axiom-orient/AxiomSideMenu.git", exact: "0.1.3") to pin this release. Retain your previously tested version so you can restore that requirement if a future upgrade fails. Published tags are immutable.

## License

MIT. See [LICENSE](LICENSE).
