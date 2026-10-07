import SwiftUI

extension View {
  /// Adds a drawer that opens from a horizontal edge.
  ///
  /// The supplied binding owns the menu's open state. A swipe from the chosen
  /// edge opens the drawer; dragging it outward or tapping the dimmed area
  /// closes it.
  ///
  /// The panel follows horizontal drags directly. A release changes the binding
  /// only when the final visible position passes half the panel's width. From
  /// either resting endpoint, this requires moving strictly more than half the
  /// width. Exactly half retains the gesture's starting committed state.
  ///
  /// The panel is mounted during presentation, dragging, and settling. Keep
  /// persistent selection, routes, and data in the app's state outside it.
  ///
  /// - Parameters:
  ///   - isPresented: The source of truth for whether the drawer is open.
  ///   - edge: The logical edge the drawer opens from.
  ///   - width: The drawer's preferred width, clamped to the available width.
  ///   - menu: The drawer content.
  /// - Returns: A view with a side menu attached.
  public func sideMenu<Menu: View>(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    @ViewBuilder menu: @escaping () -> Menu
  ) -> some View {
    sideMenu(
      isPresented: isPresented,
      edge: edge,
      width: width,
      background: BackgroundStyle(),
      menu: menu
    )
  }

  /// Adds a side menu with a panel fill that extends behind the status bar and
  /// home indicator while the menu content remains in the offered safe region.
  public func sideMenu<Menu: View, Background: ShapeStyle>(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    background: Background,
    @ViewBuilder menu: @escaping () -> Menu
  ) -> some View {
    modifier(
      SideMenuModifier(
        isPresented: isPresented,
        edge: edge,
        width: width,
        background: background,
        menu: menu
      )
    )
  }
}
