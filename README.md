# AxiomSideMenu

A small SwiftUI drawer with one app-owned presentation binding. No external dependencies. Swift 6 language mode; iOS 17+, macOS 14+, and Mac Catalyst 17+.

## Installation

In Xcode, add this package URL and select version **0.1.1** or later:

    https://github.com/axiom-orient/AxiomSideMenu.git

In a Swift package:

~~~swift
 dependencies: [
   .package(url: "https://github.com/axiom-orient/AxiomSideMenu.git", from: "0.1.1")
 ],
 targets: [
   .target(
     name: "YourApp",
     dependencies: [.product(name: "AxiomSideMenu", package: "AxiomSideMenu")]
   )
 ]
~~~

For local development, use .package(path: "../AxiomSideMenu") or Xcode's Add Local option.

## Usage

This iOS example attaches the menu outside NavigationStack so the drawer covers the navigation bar:

~~~swift
import AxiomSideMenu
import SwiftUI

struct ContentView: View {
  @State private var isMenuOpen = false

  var body: some View {
    NavigationStack {
      Text("Home")
        .navigationTitle("Home")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Menu", systemImage: "line.3.horizontal") {
              isMenuOpen = true
            }
          }
        }
    }
    .sideMenu(isPresented: $isMenuOpen, width: 280) {
      VStack(alignment: .leading, spacing: 16) {
        Button("Home") { isMenuOpen = false }
        Button("Settings") { isMenuOpen = false }
        Spacer()
      }
      .padding()
    }
  }
}
~~~

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

Bind your view with .sideMenu(isPresented: $sidebar.isPresented). An agent action running on another actor can call await sidebar.close(). Caller state changes supersede an in-flight drawer gesture. The app continues to own its routing and agent integration.

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

Attach the modifier outside `NavigationStack` for a drawer that covers the navigation bar. The panel fill and outside dimming extend behind the status bar and home indicator. Menu controls start at the top of the host's safe content region. The library does not add the same safe-area inset again or center a short menu vertically.

Use the `background:` overload to choose the fill for the whole panel, including its system safe-area bands:

~~~swift
mainContent
  .sideMenu(isPresented: $isMenuOpen, edge: .trailing, background: Color.indigo) {
    VStack(spacing: 16) {
      Text("Menu")
      ScrollView {
        // Your menu items.
      }
      Button("Close") { isMenuOpen = false }
    }
    .padding(16)
  }
~~~

The app owns its menu header, scrollable list, footer, and ordinary spacing. In the example above the list scrolls, while the header and close button remain in the safe content region. The original modifier without `background:` uses the system background style.

Implementation references and their exact commits are recorded in [source research](docs/IMPLEMENTATION_REFERENCES.md).

## Example and verification

Open Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj. The checked-in Xcode project directly references this package; XcodeGen is needed only to regenerate it from project.yml.

See [verification evidence](docs/VERIFICATION.md) for the tested revision, commands, runtime scenarios, and platform limits. The minimum compiler and OS requirements are distinct from the toolchain and runtimes actually tested.

## Version pinning and recovery

Use .package(url: "https://github.com/axiom-orient/AxiomSideMenu.git", exact: "0.1.1") to pin this release. Retain your previously tested version so you can restore that requirement if a future upgrade fails. Published tags are immutable.

## License

MIT. See [LICENSE](LICENSE).
