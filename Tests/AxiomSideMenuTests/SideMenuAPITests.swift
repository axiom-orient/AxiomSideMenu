import AxiomSideMenu
import SwiftUI
import Testing

struct SideMenuAPITests {
  @MainActor
  @Test
  func modifierIsAvailableToClients() {
    let isPresented = Binding.constant(false)
    let host = Text("Home")
      .sideMenu(isPresented: isPresented, edge: .trailing, width: 280) {
        Text("Menu")
      }

    _ = host
  }

  @MainActor
  @Test
  func panelBackgroundAcceptsAColorOrGradient() {
    _ = Text("Home")
      .sideMenu(isPresented: .constant(false), background: Color.purple) {
        Text("Menu")
      }
    _ = Text("Home")
      .sideMenu(
        isPresented: .constant(false),
        edge: .trailing,
        background: LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom)
      ) {
        Text("Menu")
      }
  }
}
