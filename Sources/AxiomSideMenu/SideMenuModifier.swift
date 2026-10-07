import SwiftUI

struct SideMenuModifier<Menu: View, Background: View>: ViewModifier {
  @Binding private var isPresented: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var layoutDirection
  @Environment(\.scenePhase) private var scenePhase

  private let edge: HorizontalEdge
  private let width: CGFloat
  private let contentInsets: EdgeInsets
  private let systemContentInsets: EdgeInsets
  private let background: () -> Background
  private let menu: () -> Menu

  @State private var hostSize: CGSize = .zero
  @State private var generation: UInt = 0
  @State private var recognition: UInt = 0
  @State private var hasInitializedPresentation = false
  @State private var presentation = SideMenuPresentation()
  // GestureState can reset before onEnded. These snapshots own admission and
  // release decisions; the presentation model owns only local visible progress.
  @State private var openingAdmission: SideMenuDragSession?
  @State private var closingAdmission: SideMenuDragSession?
  @GestureState private var isRecognizingOpening = false
  @GestureState private var isRecognizingClosing = false
  @Namespace private var gestureSpace

  init(
    isPresented: Binding<Bool>,
    edge: HorizontalEdge,
    width: CGFloat,
    contentInsets: EdgeInsets,
    systemContentInsets: EdgeInsets = .init(),
    @ViewBuilder background: @escaping () -> Background,
    @ViewBuilder menu: @escaping () -> Menu
  ) {
    self._isPresented = isPresented
    self.edge = edge
    self.width = width
    self.contentInsets = contentInsets
    self.systemContentInsets = systemContentInsets
    self.background = background
    self.menu = menu
  }

  func body(content: Content) -> some View {
    let isVisible = isPresented && context.width > 0

    content
      .accessibilityElement(children: isVisible ? .ignore : .contain)
      .accessibilityHidden(isVisible)
      .allowsHitTesting(!isVisible)
      .background {
        Color.clear.contentShape(Rectangle())
      }
      // Disable child activation once an edge drag is recognized, while the
      // observer attached outside this scope keeps following the same finger.
      .disabled(isOpeningDragActive)
      .simultaneousGesture(openingGesture, including: isVisible ? .subviews : .all)
      .overlay {
        GeometryReader { geometry in
          let panelWidth = SideMenuGeometry.resolvedWidth(
            requested: width, available: geometry.size.width)

          TimelineView(.animation(paused: presentation.motion == nil)) { _ in
            let progress = presentation.progress()

            if panelWidth > 0
              && (isPresented || progress > 0 || presentation.motion != nil
                || isOpeningDragActive || isPanelDragActive)
            {
              panel(
                progress: progress,
                width: panelWidth,
                hostSize: geometry.size
              )
            }
          }
          .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
          // Position is sampled from the local curve, rather than an implicit
          // target-value animation whose current position cannot be grabbed.
          .transaction { $0.animation = nil }
        }
      }
      .coordinateSpace(name: gestureSpace)
      .onGeometryChange(for: CGSize.self) {
        $0.size
      } action: { newSize in
        guard hostSize != newSize else { return }
        hostSize = newSize
        invalidateRecognition()
        if !hasInitializedPresentation {
          hasInitializedPresentation = true
          presentation.settle(to: isPresented, animated: false)
        } else {
          presentation.settle(to: isPresented, animated: !reduceMotion)
        }
      }
      .onChange(of: isPresented) { _, _ in
        invalidateRecognition()
        presentation.settle(to: isPresented, animated: !reduceMotion)
      }
      .onChange(of: edge) { _, _ in cancelForLayoutChange() }
      .onChange(of: context.width) { _, _ in cancelForLayoutChange() }
      .onChange(of: contentLayout) { _, _ in cancelForLayoutChange() }
      .onChange(of: layoutDirection) { _, _ in cancelForLayoutChange() }
      .onChange(of: reduceMotion) { _, isReduced in
        if isReduced {
          invalidateRecognition()
          presentation.settle(to: isPresented, animated: false)
        }
      }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active {
          invalidateRecognition()
          presentation.settle(to: isPresented, animated: false)
        }
      }
      .onChange(of: isRecognizingOpening) { _, isRecognizing in
        if !isRecognizing { cancelAfterReset(opening: true) }
      }
      .onChange(of: isRecognizingClosing) { _, isRecognizing in
        if !isRecognizing { cancelAfterReset(opening: false) }
      }
      .task(id: presentation.motion) {
        guard let motion = presentation.motion else { return }
        do {
          try await ContinuousClock().sleep(until: motion.deadline)
        } catch {
          return
        }
        presentation.finish(motion)
      }
      .onDisappear {
        invalidateRecognition()
        presentation.settle(to: isPresented, animated: false)
      }
      .accessibilityAction(.escape, closeMenu)
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

  private var alignment: Alignment { edge == .leading ? .leading : .trailing }

  private var contentLayout: SideMenuContentLayout {
    SideMenuGeometry.resolvedContentLayout(
      systemInsets: systemContentInsets,
      contentInsets: contentInsets,
      available: CGSize(width: context.width, height: hostSize.height)
    )
  }

  private var isOpeningDragActive: Bool {
    isRecognizingOpening && openingAdmission?.isHorizontal == true
      && openingAdmission?.context == context
  }

  private var isPanelDragActive: Bool {
    isRecognizingClosing && closingAdmission?.isHorizontal == true
      && closingAdmission?.context == context
  }

  private func canDragPanel(progress: CGFloat) -> Bool {
    SideMenuGeometry.canDragPanel(
      context: context,
      progress: progress,
      isSettling: presentation.motion != nil,
      isRecognizingPanel: isPanelDragActive,
      isOpeningFromContent: isOpeningDragActive
    )
  }

  private func panel(progress: CGFloat, width: CGFloat, hostSize: CGSize) -> some View {
    let visibleWidth = width * progress
    let outsideWidth = max(0, hostSize.width - visibleWidth)

    return ZStack(alignment: alignment) {
      if outsideWidth > 0 {
        HStack(spacing: 0) {
          if edge == .leading {
            Spacer(minLength: 0).frame(width: visibleWidth)
          }
          dismissArea(width: outsideWidth, progress: progress)
          if edge == .trailing {
            Spacer(minLength: 0).frame(width: visibleWidth)
          }
        }
      }

      panelContent(layout: contentLayout)
        .frame(width: width, height: hostSize.height, alignment: .topLeading)
        .background {
          ZStack {
            // Expand the background's proposal before sizing an image. The
            // content above keeps its original offered safe-region proposal.
            GeometryReader { geometry in
              background()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .ignoresSafeArea(.container, edges: .vertical)
            .disabled(true)
            .allowsHitTesting(false)

            // Absorb blank panel taps independently of the decorative view.
            Rectangle()
              .fill(.clear)
              .contentShape(Rectangle())
              .ignoresSafeArea(.container, edges: .vertical)
              .onTapGesture {}
          }
          .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.2), radius: 16)
        .offset(
          x: SideMenuGeometry.presentationOffset(progress: progress, width: width, edge: edge)
        )
        .simultaneousGesture(closingGesture)
        .allowsHitTesting(canDragPanel(progress: progress))
        .zIndex(1)
    }
    .frame(width: hostSize.width, height: hostSize.height, alignment: alignment)
    .accessibilityElement(children: .contain)
    .accessibilityAddTraits(.isModal)
    .accessibilityHidden(!isPresented)
  }

  @ViewBuilder
  private func panelContent(layout: SideMenuContentLayout) -> some View {
    if layout.systemInsets == EdgeInsets() {
      // Advanced modifiers retain their original offered-safe-region layout.
      menu().disabled(!isPresented).padding(layout.contentInsets)
    } else {
      menu()
        .disabled(!isPresented)
        .padding(layout.contentInsets)
        .safeAreaPadding(layout.systemInsets)
    }
  }

  private func dismissArea(width: CGFloat, progress: CGFloat) -> some View {
    Color.black.opacity(0.45 * progress)
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
      .onKeyPress(.escape) {
        closeMenu()
        return .handled
      }
      .simultaneousGesture(closingGesture)
      .allowsHitTesting(isPresented)
  }

  private var openingGesture: some Gesture {
    DragGesture(minimumDistance: 8, coordinateSpace: .named(gestureSpace))
      .updating($isRecognizingOpening) { value, isRecognizing, transaction in
        if !isRecognizing {
          isRecognizing = true
          openingAdmission = nil
          let current = context
          guard
            !current.isPresented,
            SideMenuGeometry.canStartDrag(
              startX: value.startLocation.x, availableWidth: hostSize.width, context: current)
          else { return }
          openingAdmission = beginSession(context: current, value: value)
        }
        update(&openingAdmission, value: value)
        transaction.disablesAnimations = true
      }
      .onEnded { value in
        let session = openingAdmission
        openingAdmission = nil
        release(session, value: value)
      }
  }

  private var closingGesture: some Gesture {
    DragGesture(minimumDistance: 8, coordinateSpace: .named(gestureSpace))
      .updating($isRecognizingClosing) { value, isRecognizing, transaction in
        if !isRecognizing {
          isRecognizing = true
          closingAdmission = nil
          let current = context
          guard canDragPanel(progress: presentation.progress()) else { return }
          closingAdmission = beginSession(context: current, value: value)
        }
        update(&closingAdmission, value: value)
        transaction.disablesAnimations = true
      }
      .onEnded { value in
        let session = closingAdmission
        closingAdmission = nil
        release(session, value: value)
      }
  }

  private func beginSession(context: SideMenuDragContext, value: DragGesture.Value)
    -> SideMenuDragSession
  {
    recognition &+= 1
    return presentation.recognize(
      context: context,
      translation: value.translation,
      recognition: recognition
    )
  }

  private func update(_ admission: inout SideMenuDragSession?, value: DragGesture.Value) {
    guard var session = admission, session.context == context else { return }
    session.update(translation: value.translation)
    admission = session
    if session.isHorizontal { presentation.track(session.progress(in: context)) }
  }

  private func release(_ admission: SideMenuDragSession?, value: DragGesture.Value) {
    guard var session = admission else { return }
    session.update(translation: value.translation)
    guard let target = session.target(in: context) else { return }
    presentation.track(session.progress(in: context))
    if target != isPresented { isPresented = target }
    presentation.settle(to: target, animated: !reduceMotion)
  }

  private func cancelAfterReset(opening: Bool) {
    guard let session = opening ? openingAdmission : closingAdmission else { return }
    // Reset is also observed before a normal onEnded on some OS versions.
    // Keep the snapshot inert so that release can still consume it. Cancellation
    // has no onEnded; the next recognition or external change replaces it.
    guard session.isHorizontal, session.context == context else { return }
    presentation.settle(to: isPresented, animated: !reduceMotion)
  }

  private func cancelForLayoutChange() {
    invalidateRecognition()
    presentation.settle(to: isPresented, animated: !reduceMotion)
  }

  private func invalidateRecognition() {
    generation &+= 1
    openingAdmission = nil
    closingAdmission = nil
  }

  private func closeMenu() {
    guard isPresented else { return }
    isPresented = false
  }
}
