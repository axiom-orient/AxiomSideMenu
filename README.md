# AxiomSideMenu

A small SwiftUI side drawer for iOS, macOS, and Mac Catalyst. It uses Swift 6 language mode and has no package dependencies.

## Add the package

In Xcode, choose **File → Add Package Dependencies → Add Local…** and select this folder.

For another Swift package, add a local dependency:

    .package(path: "../AxiomSideMenu")

Then add AxiomSideMenu to the app target's dependencies and import the module.

## Use it

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
                }
                .padding()
            }
        }
    }

The isPresented binding owns the open state. A swipe inward from the selected edge opens the menu. Dragging the menu outward, tapping the dimmed area, or using the accessibility escape action closes it. Vertical scrolling inside the menu remains available.

Use edge: .trailing to open from the other side. Width is a preferred width and is clamped to the available space.

## Example

Open Examples/iOSDemo/AxiomSideMenuDemo.xcodeproj for a runnable iOS example. It includes a UI test for opening by button or edge swipe and dismissing from the dimmed area.

## Requirements

- Swift 6.0 or later
- iOS 17 or later
- macOS 14 or later
- Mac Catalyst 17 or later

## License

MIT. See LICENSE.
