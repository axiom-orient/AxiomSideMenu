import SwiftUI

/// A root container whose panel and input surface include the available system
/// safe-area bands, while main and menu foregrounds retain safe layout guides.
///
/// Place `NavigationStack` inside the content closure when the drawer should
/// cover its navigation bar. Intrinsic content also receives a full-size host.
/// The container restores the host's safe area and delegates drawer behavior,
/// extra content padding, and background layout to the `sideMenu` modifier.
///
/// Ancestor navigation, clipping, and ignored safe-area information still limit
/// the offered region. The container does not infer a global window's bounds.
public struct SideMenu<Content: View, Menu: View, Background: View>: View {
  @Binding private var isPresented: Bool
  @Environment(\.layoutDirection) private var layoutDirection
  private let edge: HorizontalEdge
  private let width: CGFloat
  private let contentInsets: EdgeInsets
  private let content: () -> Content
  private let menu: () -> Menu
  private let background: (() -> Background)?

  /// Creates a root drawer with a decorative full-panel background view.
  ///
  /// - Parameters:
  ///   - isPresented: The app-owned committed presentation state.
  ///   - edge: Logical horizontal edge, defaulting to leading.
  ///   - width: Preferred panel width, defaulting to 280 and capped to the host.
  ///   - contentInsets: Additional padding inside the offered safe menu region,
  ///     defaulting to zero. Supply a measured top reservation when needed.
  ///   - content: Main content, expanded to fill the offered host region.
  ///   - menu: Drawer content laid out by the canonical `sideMenu` modifier.
  ///   - background: Decorative panel content; use `resizable().scaledToFill()`
  ///     for an image that fills its complete bounds, including safe-area bands.
  public init(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    contentInsets: EdgeInsets = .init(),
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder menu: @escaping () -> Menu,
    @ViewBuilder background: @escaping () -> Background
  ) {
    self._isPresented = isPresented
    self.edge = edge
    self.width = width
    self.contentInsets = contentInsets
    self.content = content
    self.menu = menu
    self.background = background
  }

  public var body: some View {
    GeometryReader { outer in
      GeometryReader { canvas in
        let restoredInsets = SideMenuGeometry.restoredSafeAreaInsets(
          outer: outer.safeAreaInsets,
          inner: canvas.safeAreaInsets,
          available: canvas.size
        )
        let panelInsets = SideMenuGeometry.panelSafeAreaInsets(
          canvas: canvas.size,
          containerInsets: restoredInsets,
          panelWidth: width,
          edge: edge,
          layoutDirection: layoutDirection
        )
        drawerCanvas(size: canvas.size, mainInsets: restoredInsets, panelInsets: panelInsets)
      }
      .ignoresSafeArea(.container)
    }
  }

  @ViewBuilder
  private func drawerCanvas(size: CGSize, mainInsets: EdgeInsets, panelInsets: EdgeInsets)
    -> some View
  {
    if let background {
      mainContent(size: size, insets: mainInsets)
        .modifier(
          SideMenuModifier(
            isPresented: $isPresented,
            edge: edge,
            width: width,
            contentInsets: contentInsets,
            systemContentInsets: panelInsets,
            background: background,
            menu: menu
          )
        )
    } else {
      mainContent(size: size, insets: mainInsets)
        .modifier(
          SideMenuModifier(
            isPresented: $isPresented,
            edge: edge,
            width: width,
            contentInsets: contentInsets,
            systemContentInsets: panelInsets,
            background: { Rectangle().fill(BackgroundStyle()) },
            menu: menu
          )
        )
    }
  }

  private func mainContent(size: CGSize, insets: EdgeInsets) -> some View {
    content()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .safeAreaPadding(insets)
      .frame(width: size.width, height: size.height)
  }
}

extension SideMenu where Background == EmptyView {
  /// Creates a root drawer with the system panel background.
  ///
  /// The binding and all layout defaults match the `sideMenu` modifier. Main
  /// content fills the offered host while preserving its safe-area behavior.
  public init(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge = .leading,
    width: CGFloat = 280,
    contentInsets: EdgeInsets = .init(),
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder menu: @escaping () -> Menu
  ) {
    self._isPresented = isPresented
    self.edge = edge
    self.width = width
    self.contentInsets = contentInsets
    self.content = content
    self.menu = menu
    self.background = nil
  }
}
