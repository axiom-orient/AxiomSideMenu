import SwiftUI

extension View {
  /// Adds a drawer that opens from a horizontal edge.
  ///
  /// The supplied binding owns the menu's open state. A swipe from the chosen
  /// edge opens the drawer; dragging it outward or tapping the dimmed area
  /// closes it.
  ///
  /// The panel is mounted only while the binding is true and its width is
  /// positive. Opening swipes commit on release. Keep
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
    modifier(
      SideMenuModifier(
        isPresented: isPresented,
        edge: edge,
        width: width,
        menu: menu
      )
    )
  }
}
