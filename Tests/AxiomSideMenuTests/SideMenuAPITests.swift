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

  @MainActor
  @Test
  func additionalContentInsetsWorkWithDefaultAndStyleBackgrounds() {
    let insets = EdgeInsets(top: 52, leading: 12, bottom: 8, trailing: 12)
    _ = Text("Home")
      .sideMenu(isPresented: .constant(false), contentInsets: insets) {
        Text("Menu")
      }
    _ = Text("Home")
      .sideMenu(
        isPresented: .constant(false), contentInsets: insets, background: Color.indigo
      ) {
        Text("Menu")
      }
  }

  @MainActor
  @Test
  func decorativeImageBackgroundSupportsDefaultAndAdditionalInsets() {
    _ = Text("Home")
      .sideMenu(isPresented: .constant(false)) {
        Text("Menu")
      } background: {
        Image(systemName: "photo").resizable().scaledToFill()
      }
    _ = Text("Home")
      .sideMenu(
        isPresented: .constant(false),
        edge: .trailing,
        contentInsets: EdgeInsets(top: 52, leading: 0, bottom: 0, trailing: 0)
      ) {
        Text("Menu")
      } background: {
        Image(systemName: "photo").resizable().scaledToFill()
      }
  }

  @MainActor
  @Test
  func originalMethodReferenceSignaturesRemainAvailable() {
    useOriginal(Text("Home").sideMenu(isPresented:edge:width:menu:))
    useOriginalStyle(Text("Home").sideMenu(isPresented:edge:width:background:menu:))
  }

  @MainActor
  private func useOriginal<Result: View>(
    _ modifier: (Binding<Bool>, HorizontalEdge, CGFloat, @escaping () -> Text) -> Result
  ) {
    _ = modifier(.constant(false), .leading, 280, { Text("Menu") })
  }

  @MainActor
  private func useOriginalStyle<Result: View>(
    _ modifier: (Binding<Bool>, HorizontalEdge, CGFloat, Color, @escaping () -> Text) -> Result
  ) {
    _ = modifier(.constant(false), .trailing, 280, .indigo, { Text("Menu") })
  }
}
