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
      contentInsets: .init(),
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
    sideMenu(
      isPresented: isPresented,
      edge: edge,
      width: width,
      contentInsets: .init(),
      background: background,
      menu: menu
    )
  }

  /// Adds a side menu with extra content padding inside the host's safe region.
  ///
  /// Use a measured navigation-bar height as the top inset when that additional
  /// reservation is desired. The library does not add the system safe-area
  /// inset again. Ordinary padding supplied inside the menu remains additional.
  /// Negative and non-finite inset values are zero; insets are capped to the
  /// available content region. Leading and trailing follow the layout direction.
  public func sideMenu<Menu: View>(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    contentInsets: EdgeInsets,
    @ViewBuilder menu: @escaping () -> Menu
  ) -> some View {
    sideMenu(
      isPresented: isPresented,
      edge: edge,
      width: width,
      contentInsets: contentInsets,
      background: BackgroundStyle(),
      menu: menu
    )
  }

  /// Adds extra safe-region content padding and a fill for the entire panel.
  ///
  /// `contentInsets` reserves additional space inside the host's offered safe
  /// region; it does not replace or repeat the system safe-area padding.
  public func sideMenu<Menu: View, Background: ShapeStyle>(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    contentInsets: EdgeInsets,
    background: Background,
    @ViewBuilder menu: @escaping () -> Menu
  ) -> some View {
    sideMenu(
      isPresented: isPresented,
      edge: edge,
      width: width,
      contentInsets: contentInsets,
      menu: menu,
      background: { Rectangle().fill(background) }
    )
  }

  /// Adds a side menu with a decorative background view covering the full
  /// panel, including its status-bar and home-indicator safe-area bands.
  ///
  /// The background receives the full panel size and is clipped to its bounds.
  /// For an image that fills those bounds, use `resizable().scaledToFill()`.
  /// Background controls and accessibility elements are inactive.
  ///
  /// - Parameters:
  ///   - isPresented: The source of truth for the committed presentation state.
  ///   - edge: The logical horizontal edge; it follows the layout direction.
  ///   - width: Preferred panel width, clamped to the available host width.
  ///   - contentInsets: Additional padding inside the offered safe region,
  ///     defaulting to zero. Supply a measured top reservation when needed.
  ///     Negative or non-finite values are zero; values are capped to the region.
  ///   - menu: Content placed at the top of that safe region.
  ///   - background: Decorative content laid out in the complete panel bounds.
  ///
  /// Attach the modifier outside `NavigationStack` to cover its navigation bar.
  /// Ancestor clipping or consumed safe-area information limits the available
  /// panel region; the library does not query a global application window.
  public func sideMenu<Menu: View, Background: View>(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    contentInsets: EdgeInsets = .init(),
    @ViewBuilder menu: @escaping () -> Menu,
    @ViewBuilder background: @escaping () -> Background
  ) -> some View {
    modifier(
      SideMenuModifier(
        isPresented: isPresented,
        edge: edge,
        width: width,
        contentInsets: contentInsets,
        background: background,
        menu: menu
      )
    )
  }
}
