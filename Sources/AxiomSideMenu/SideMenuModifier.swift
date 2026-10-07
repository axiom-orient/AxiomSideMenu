import SwiftUI

struct SideMenuModifier<Menu: View>: ViewModifier {
  @Binding private var isPresented: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var layoutDirection
  @Environment(\.scenePhase) private var scenePhase

  private let edge: HorizontalEdge
  private let width: CGFloat
  private let menu: () -> Menu

  @State private var hostSize: CGSize = .zero
  @State private var generation: UInt = 0
  // SwiftUI can reset GestureState before onEnded. This recognition snapshot
  // is used only for committing; it never drives presentation or hit testing.
  @State private var openingAdmission: SideMenuDragSession?
  @State private var closingAdmission: SideMenuDragSession?
  @GestureState private var isRecognizingOpening = false
  @GestureState private var closingDrag: SideMenuDragSession?
  @Namespace private var gestureSpace

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
    let isVisible = isPresented && context.width > 0
    let isOpeningHorizontally = isRecognizingOpening && openingAdmission?.isHorizontal == true

    content
      .accessibilityElement(children: isVisible ? .ignore : .contain)
      .accessibilityHidden(isVisible)
      .allowsHitTesting(!isVisible)
      .background {
        // Admit drags in a transparent host's blank area behind its controls.
        Color.clear.contentShape(Rectangle())
      }
      // Cancelling a recognized edge drag must not activate a child Button.
      // The observer is attached after this scope so it remains enabled.
      .disabled(isOpeningHorizontally)
      .simultaneousGesture(openingGesture, including: isVisible ? .subviews : .all)
      .overlay {
        GeometryReader { geometry in
          let panelWidth = SideMenuGeometry.resolvedWidth(
            requested: width,
            available: geometry.size.width
          )

          ZStack(alignment: alignment) {
            if isPresented && panelWidth > 0 {
              let offset = closingDrag?.offset(in: context) ?? 0
              let visibleWidth = max(0, panelWidth - abs(offset))
              let outsideWidth = max(0, geometry.size.width - visibleWidth)

              ZStack(alignment: alignment) {
                if outsideWidth > 0 {
                  HStack(spacing: 0) {
                    if edge == .leading {
                      Spacer(minLength: 0).frame(width: visibleWidth)
                    }
                    dismissArea(width: outsideWidth)
                    if edge == .trailing {
                      Spacer(minLength: 0).frame(width: visibleWidth)
                    }
                  }
                  .transition(.opacity)
                }

                menu()
                  .padding(geometry.safeAreaInsets)
                  .frame(width: panelWidth)
                  .frame(maxHeight: .infinity)
                  .background {
                    // Absorb blank panel taps behind its native child controls.
                    Rectangle()
                      .fill(.background)
                      .ignoresSafeArea(.container, edges: .vertical)
                      .onTapGesture {}
                      .accessibilityHidden(true)
                  }
                  .shadow(color: .black.opacity(0.2), radius: 16)
                  .offset(x: offset)
                  .transition(.move(edge: edge == .leading ? .leading : .trailing))
                  .zIndex(1)
              }
              .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
              .accessibilityElement(children: .contain)
              .accessibilityAddTraits(.isModal)
              .simultaneousGesture(closingGesture)
            }
          }
          .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
          .animation(animation, value: isPresented)
          .animation(animation, value: closingDrag == nil)
        }
      }
      .coordinateSpace(name: gestureSpace)
      .onGeometryChange(for: CGSize.self) { geometry in
        geometry.size
      } action: { newSize in
        guard hostSize != newSize else { return }
        hostSize = newSize
        invalidateRecognition()
      }
      .onChange(of: isPresented) { _, _ in
        invalidateRecognition()
      }
      .onChange(of: edge) { _, _ in invalidateRecognition() }
      .onChange(of: context.width) { _, _ in invalidateRecognition() }
      .onChange(of: layoutDirection) { _, _ in invalidateRecognition() }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { invalidateRecognition() }
      }
      .onDisappear(perform: invalidateRecognition)
      .accessibilityAction(.escape) {
        if isPresented { closeMenu() }
      }
  }

  private var context: SideMenuDragContext {
    SideMenuDragContext(
      isPresented: isPresented,
      width: SideMenuGeometry.resolvedWidth(requested: width, available: hostSize.width),
      inwardDirection: SideMenuGeometry.inwardDirection(
        edge: edge, layoutDirection: layoutDirection),
      generation: generation
    )
  }

  private var alignment: Alignment {
    edge == .leading ? .leading : .trailing
  }

  private var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.28)
  }

  private func dismissArea(width: CGFloat) -> some View {
    Color.black.opacity(0.45)
      .frame(width: width)
      .frame(maxHeight: .infinity)
      .contentShape(Rectangle())
      .ignoresSafeArea(.container, edges: .vertical)
      .onTapGesture(perform: closeMenu)
      .accessibilityLabel("Close menu")
      .accessibilityAddTraits(.isButton)
      .accessibilityAction(.default, closeMenu)
      .focusable(interactions: .activate)
      .onKeyPress(.space) {
        closeMenu()
        return .handled
      }
      .onKeyPress(.return) {
        closeMenu()
        return .handled
      }
  }

  /// A passive recognizer observes primary content without mounting a drawer.
  /// Rejected or cancelled opening drags never change its hit testing.
  private var openingGesture: some Gesture {
    DragGesture(minimumDistance: 8, coordinateSpace: .named(gestureSpace))
      .updating($isRecognizingOpening) { value, isRecognizing, _ in
        guard !isRecognizing else { return }
        isRecognizing = true
        openingAdmission = nil
        let current = context
        guard
          !current.isPresented,
          SideMenuGeometry.canStartDrag(
            startX: value.startLocation.x,
            availableWidth: hostSize.width,
            context: current
          )
        else { return }
        openingAdmission = SideMenuDragSession(context: current, translation: value.translation)
      }
      .onEnded { value in
        defer { openingAdmission = nil }
        commit(openingAdmission, value: value)
      }
  }

  /// This recognizer exists only over the mounted panel and outside scrim.
  /// GestureState owns visible progress; recognition metadata owns admission.
  private var closingGesture: some Gesture {
    DragGesture(minimumDistance: 8, coordinateSpace: .named(gestureSpace))
      .updating($closingDrag) { value, session, transaction in
        if session == nil {
          closingAdmission = nil
          let current = context
          guard current.isPresented && current.width > 0 else { return }
          session = SideMenuDragSession(context: current, translation: value.translation)
          closingAdmission = session
        }
        session?.update(translation: value.translation)
        transaction.disablesAnimations = true
      }
      .onEnded { value in
        defer { closingAdmission = nil }
        commit(closingAdmission, value: value)
      }
  }

  private func commit(_ admission: SideMenuDragSession?, value: DragGesture.Value) {
    guard var session = admission else { return }
    session.update(translation: value.translation)
    guard
      let target = session.target(
        in: context,
        predictedTranslation: value.predictedEndTranslation.width
      ),
      target != isPresented
    else { return }
    withAnimation(animation) {
      isPresented = target
    }
  }

  private func invalidateRecognition() {
    generation &+= 1
    openingAdmission = nil
    closingAdmission = nil
  }

  private func closeMenu() {
    guard isPresented else { return }
    withAnimation(animation) {
      isPresented = false
    }
  }
}
