import SwiftUI

extension View {
  /// Adds a drawer that opens from a horizontal edge.
  ///
  /// The supplied binding owns the menu's open state. A swipe from the chosen
  /// edge opens the drawer; dragging it outward or tapping the dimmed area
  /// closes it.
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

private struct SideMenuModifier<Menu: View>: ViewModifier {
  @Binding private var isPresented: Bool

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var layoutDirection

  private let edge: HorizontalEdge
  private let width: CGFloat
  private let menu: () -> Menu

  @State private var dragOffset: CGFloat = 0

  init(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge,
    width: CGFloat,
    @ViewBuilder menu: @escaping () -> Menu
  ) {
    self._isPresented = isPresented
    self.edge = edge
    self.width = width
    self.menu = menu
  }

  func body(content: Content) -> some View {
    content
      .allowsHitTesting(!isInteractionActive)
      .accessibilityHidden(isInteractionActive)
      .overlay {
        GeometryReader { geometry in
          let panelWidth = SideMenuGeometry.resolvedWidth(
            requested: width,
            available: geometry.size.width
          )

          ZStack(alignment: alignment) {
            if isPresented {
              dismissArea(panelWidth: panelWidth)
                .transition(.opacity)
                .zIndex(0)
            }

            if !isPresented {
              edgeSwipeArea(availableWidth: geometry.size.width, panelWidth: panelWidth)
                .zIndex(1)
            }

            menu()
              .frame(width: panelWidth)
              .frame(maxHeight: .infinity)
              .background(.background)
              .shadow(color: .black.opacity(0.2), radius: 16)
              .offset(x: panelOffset(width: panelWidth))
              .allowsHitTesting(isPresented)
              .accessibilityHidden(!isPresented)
              .simultaneousGesture(dragGesture(isOpen: true, panelWidth: panelWidth))
              .zIndex(2)
          }
          .frame(width: geometry.size.width, height: geometry.size.height)
          .ignoresSafeArea()
          .animation(animation, value: isPresented)
          .onChange(of: isPresented) { _, _ in
            dragOffset = 0
          }
        }
      }
      .accessibilityAction(.escape) {
        if isPresented {
          closeMenu()
        }
      }
  }

  private var alignment: Alignment {
    edge == .leading ? .leading : .trailing
  }

  /// Positive values point from the selected edge toward the center.
  private var inwardDirection: CGFloat {
    let edgeIsLeftInCurrentDirection =
      (edge == .leading) == (layoutDirection == .leftToRight)
    return edgeIsLeftInCurrentDirection ? 1 : -1
  }

  private var isInteractionActive: Bool {
    isPresented || dragOffset != 0
  }

  private var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.28)
  }

  private func panelOffset(width: CGFloat) -> CGFloat {
    if isPresented {
      return dragOffset
    }

    return -inwardDirection * width + dragOffset
  }

  private func dismissArea(panelWidth: CGFloat) -> some View {
    Button(action: closeMenu) {
      Color.black.opacity(0.45)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .ignoresSafeArea()
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Close menu")
    .simultaneousGesture(dragGesture(isOpen: true, panelWidth: panelWidth))
  }

  private func edgeSwipeArea(availableWidth: CGFloat, panelWidth: CGFloat) -> some View {
    Color.clear
      .frame(width: min(28, max(0, availableWidth)))
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
      .accessibilityHidden(true)
      .gesture(dragGesture(isOpen: false, panelWidth: panelWidth))
  }

  private func dragGesture(isOpen: Bool, panelWidth: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 8)
      .onChanged { value in
        guard isHorizontal(value) else { return }
        dragOffset = SideMenuGeometry.dragOffset(
          translation: value.translation.width,
          isOpen: isOpen,
          width: panelWidth,
          inwardDirection: inwardDirection
        )
      }
      .onEnded { value in
        guard isHorizontal(value) else {
          withAnimation(animation) {
            dragOffset = 0
          }
          return
        }

        let shouldToggle = SideMenuGeometry.shouldToggle(
          translation: value.translation.width,
          predictedTranslation: value.predictedEndTranslation.width,
          isOpen: isOpen,
          threshold: panelWidth * 0.3,
          inwardDirection: inwardDirection
        )

        withAnimation(animation) {
          if shouldToggle {
            isPresented = !isOpen
          }
          dragOffset = 0
        }
      }
  }

  private func isHorizontal(_ value: DragGesture.Value) -> Bool {
    abs(value.translation.width) > abs(value.translation.height)
  }

  private func closeMenu() {
    withAnimation(animation) {
      isPresented = false
      dragOffset = 0
    }
  }
}

enum SideMenuGeometry {
  static func resolvedWidth(requested: CGFloat, available: CGFloat) -> CGFloat {
    guard !requested.isNaN else { return 0 }
    return min(max(0, requested), max(0, available))
  }

  static func dragOffset(
    translation: CGFloat,
    isOpen: Bool,
    width: CGFloat,
    inwardDirection: CGFloat
  ) -> CGFloat {
    let distanceTowardCenter = translation * inwardDirection
    let boundedDistance: CGFloat

    if isOpen {
      boundedDistance = max(-width, min(0, distanceTowardCenter))
    } else {
      boundedDistance = min(width, max(0, distanceTowardCenter))
    }

    return boundedDistance * inwardDirection
  }

  static func shouldToggle(
    translation: CGFloat,
    predictedTranslation: CGFloat,
    isOpen: Bool,
    threshold: CGFloat,
    inwardDirection: CGFloat
  ) -> Bool {
    let current = translation * inwardDirection
    let predicted = predictedTranslation * inwardDirection
    let threshold = max(0, threshold)

    if isOpen {
      return min(current, predicted) < -threshold
    }

    return max(current, predicted) > threshold
  }
}
