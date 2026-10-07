import AxiomSideMenu
import SwiftUI
import UIKit

struct ContentView: View {
  @Environment(\.layoutDirection) private var systemLayoutDirection

  @State private var isMenuOpen = false
  @State private var openButtonActionCount = 0
  @State private var edgeTapCount = 0
  @State private var oppositeEdgeActionCount = 0
  @State private var isSheetPresented = false
  @State private var scheduledAction: ScheduledAction?
  @State private var closesOnContactIsArmed = false
  @State private var contactActionCount = 0
  @State private var measurement = MenuFrameMeasurement()

  private let configuration = DemoConfiguration()

  var body: some View {
    menuHost
      .environment(
        \.layoutDirection,
        configuration.isRightToLeft ? .rightToLeft : systemLayoutDirection
      )
      .overlay(alignment: .bottom) {
        if configuration.showsGeometryDiagnostics {
          FrameDiagnosticsLabel(
            measurement: measurement, isPresented: $isMenuOpen,
            contactArmed: $closesOnContactIsArmed, contactActionCount: $contactActionCount
          )
          .frame(height: 18)
          .allowsHitTesting(false)
        }
      }
      .sheet(isPresented: $isSheetPresented) {
        VStack(spacing: 20) {
          Text("System sheet")
            .accessibilityIdentifier("system-sheet")

          Button("Dismiss sheet") {
            isSheetPresented = false
          }
          .accessibilityIdentifier("dismiss-sheet")
        }
        .presentationDetents([.medium])
      }
      .task(id: scheduledAction) {
        guard let action = scheduledAction else { return }

        do {
          try await Task.sleep(for: .seconds(3))
        } catch {
          // A replaced action or disappearing demo cancels its pending action.
          return
        }

        switch action {
        case .presentSheet:
          isSheetPresented = true
        case .openMenu:
          isMenuOpen = true
        case .closeMenu:
          isMenuOpen = false
        }
        scheduledAction = nil
      }
  }

  @ViewBuilder
  private var menuHost: some View {
    if configuration.usesRootContainer {
      rootMenuHost
    } else if configuration.usesImageBackground {
      hostContent
        .sideMenu(
          isPresented: $isMenuOpen,
          edge: configuration.edge,
          width: configuration.width,
          contentInsets: configuration.contentInsets
        ) {
          menuContent
        } background: {
          Image(uiImage: Self.diagnosticBackgroundImage)
            .resizable()
            .interpolation(.none)
        }
    } else if configuration.showsGeometryDiagnostics {
      hostContent
        .sideMenu(
          isPresented: $isMenuOpen,
          edge: configuration.edge,
          width: configuration.width,
          background: Color(red: 1, green: 0, blue: 1)
        ) {
          menuContent
        }
    } else {
      hostContent
        .sideMenu(isPresented: $isMenuOpen, edge: configuration.edge, width: configuration.width) {
          menuContent
        }
    }
  }

  @ViewBuilder
  private var rootMenuHost: some View {
    if configuration.usesImageBackground {
      SideMenu(
        isPresented: $isMenuOpen,
        edge: configuration.edge,
        width: configuration.width,
        contentInsets: configuration.contentInsets
      ) {
        hostContent
      } menu: {
        menuContent
      } background: {
        Image(uiImage: Self.diagnosticBackgroundImage)
          .resizable()
          .interpolation(.none)
      }
    } else if configuration.usesMagentaRootBackground {
      SideMenu(
        isPresented: $isMenuOpen,
        edge: configuration.edge,
        width: configuration.width,
        contentInsets: configuration.contentInsets
      ) {
        hostContent
      } menu: {
        menuContent
      } background: {
        Color(red: 1, green: 0, blue: 1)
      }
    } else {
      SideMenu(
        isPresented: $isMenuOpen,
        edge: configuration.edge,
        width: configuration.width,
        contentInsets: configuration.contentInsets
      ) {
        hostContent
      } menu: {
        menuContent
      }
    }
  }

  private var hostContent: some View {
    Group {
      if configuration.usesPlainHost {
        mainContent
      } else {
        NavigationStack {
          mainContent
            .navigationTitle("AxiomSideMenu")
        }
      }
    }
    .background {
      if configuration.showsGeometryDiagnostics {
        GeometryReader { geometry in
          let observation = HostGeometryObservation(
            size: geometry.size,
            frame: geometry.frame(in: .global),
            insets: geometry.safeAreaInsets
          )
          Color.clear
            .onAppear {
              measurement.host = observation
            }
            .onChange(of: observation) { _, newValue in
              measurement.host = newValue
            }
        }
        .allowsHitTesting(false)
      }
    }
  }

  private var mainItems: some View {
    VStack(spacing: 16) {
      Text("Main screen")
        .accessibilityIdentifier("main-screen")

      Button("Open menu") {
        openButtonActionCount += 1
        isMenuOpen = true
      }
      .accessibilityIdentifier("open-menu")

      Text("Edge taps: \(edgeTapCount)")
        .accessibilityIdentifier("edge-tap-count")

      Text(verbatim: "Menu intent: \(isMenuOpen)")
        .accessibilityIdentifier("menu-intent")

      if configuration.showsDiagnosticActionCount {
        Text("Opposite edge actions: \(oppositeEdgeActionCount)")
          .accessibilityIdentifier("outside-action-count")
      }

      if configuration.showsGeometryDiagnostics {
        resetMeasurementButton(identifier: "reset-main-motion")
      }

      if configuration.showsInteractionScenarios {
        interruptionControls
      }
    }
  }

  @ViewBuilder
  private var sizedMainContent: some View {
    if configuration.usesIntrinsicHost {
      mainItems
    } else {
      mainItems
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var mainContent: some View {
    sizedMainContent
      .overlay(alignment: configuration.edge == .leading ? .leading : .trailing) {
        Button {
          edgeTapCount += 1
        } label: {
          Image(systemName: "hand.tap")
            .frame(width: 28, height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tap edge control")
        .accessibilityIdentifier("edge-action")
      }
      .overlay(alignment: configuration.edge == .leading ? .trailing : .leading) {
        if configuration.showsDiagnosticActionCount {
          Button {
            oppositeEdgeActionCount += 1
          } label: {
            Image(systemName: "hand.tap")
              .frame(width: 28, height: 52)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Tap opposite edge control")
          .accessibilityIdentifier("outside-action")
        }
      }
  }

  @ViewBuilder
  private var menuContent: some View {
    if configuration.closesOnContact {
      menuSurface
        .overlay {
          GeometryReader { geometry in
            Color.clear
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
              .onLongPressGesture(
                minimumDuration: 10,
                maximumDistance: 250,
                perform: {},
                onPressingChanged: closeMenuOnContact
              )
              .accessibilityElement(children: .ignore)
              .accessibilityLabel("Contact close test region")
              .accessibilityIdentifier("contact-close-region")
              .position(x: 60, y: geometry.size.height * 0.6)
          }
        }
    } else {
      menuSurface
    }
  }

  @ViewBuilder
  private var menuSurface: some View {
    if configuration.showsGeometryDiagnostics {
      sizedMenuContent
        .padding(16)
        .background {
          NativeMenuFrameProbe(
            measurement: measurement,
            isPresented: $isMenuOpen,
            opensFromRight: opensFromRight,
            capturesHeldFrames: configuration.capturesHeldFrames,
            captureStem: configuration.captureStem
          )
          .allowsHitTesting(false)
          .accessibilityHidden(true)
        }
    } else {
      sizedMenuContent
        .padding(16)
        .background(.background)
    }
  }

  @ViewBuilder
  private var sizedMenuContent: some View {
    if configuration.usesShortMenu {
      menuItems
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      menuItems
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
  }

  private var menuItems: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Menu is open")
        .accessibilityIdentifier("menu-open")

      if configuration.showsDiagnosticActionCount {
        Text("Open button actions: \(openButtonActionCount)")
          .accessibilityIdentifier("menu-open-action-count")
      }

      Button("Home") {
        isMenuOpen = false
      }
      .accessibilityIdentifier("menu-home")

      if configuration.showsGeometryDiagnostics {
        resetMeasurementButton(identifier: "reset-menu-motion")
      }

      if configuration.showsInteractionScenarios {
        Button("Close menu after a delay") {
          if configuration.closesOnContact {
            closesOnContactIsArmed = true
          } else {
            scheduledAction = .closeMenu
          }
        }
        .accessibilityIdentifier("schedule-menu-close")
      }

      if !configuration.usesShortMenu {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            ForEach(1...20, id: \.self) { index in
              Text("Menu item \(index)")
                .accessibilityIdentifier("menu-item-\(index)")
            }
          }
        }
        .accessibilityIdentifier("menu-scroll-view")

        if configuration.showsGeometryDiagnostics {
          Button("Bottom action") {
            isMenuOpen = false
          }
          .accessibilityIdentifier("menu-bottom")
        }
      }
    }
  }

  private func resetMeasurementButton(identifier: String) -> some View {
    Button("Reset frame measurement") {
      measurement.reset()
    }
    .accessibilityIdentifier(identifier)
  }

  private func closeMenuOnContact(_ isPressing: Bool) {
    guard isPressing && closesOnContactIsArmed else { return }
    closesOnContactIsArmed = false
    contactActionCount += 1
    isMenuOpen = false
  }

  private var opensFromRight: Bool {
    let direction = configuration.isRightToLeft ? .rightToLeft : systemLayoutDirection
    return (configuration.edge == .trailing) == (direction == .leftToRight)
  }

  private var interruptionControls: some View {
    VStack(spacing: 16) {
      Button("Present sheet after a delay") {
        scheduledAction = .presentSheet
      }
      .accessibilityIdentifier("schedule-sheet")

      Button("Open menu after a delay") {
        scheduledAction = .openMenu
      }
      .accessibilityIdentifier("schedule-open")

      Button("Open menu, then close after a delay") {
        isMenuOpen = true
        scheduledAction = .closeMenu
      }
      .accessibilityIdentifier("schedule-close")
    }
  }

  private enum ScheduledAction: Hashable {
    case presentSheet
    case openMenu
    case closeMenu
  }

  /// A real raster image whose three bands expose safe-region-only stretching.
  /// It is created only by the demo fixture and is never a library fallback.
  private static let diagnosticBackgroundImage: UIImage = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: CGSize(width: 32, height: 96), format: format).image {
      context in
      for (index, color) in [UIColor.red, UIColor.green, UIColor.blue].enumerated() {
        color.setFill()
        context.fill(CGRect(x: 0, y: CGFloat(index) * 32, width: 32, height: 32))
      }
    }
  }()
}

private struct DemoConfiguration {
  private let arguments = ProcessInfo.processInfo.arguments

  var edge: HorizontalEdge {
    arguments.contains("--trailing") ? .trailing : .leading
  }

  var width: CGFloat {
    arguments.contains("--zero-width") ? 0 : 280
  }

  var isRightToLeft: Bool {
    arguments.contains("--rtl")
  }

  var showsInteractionScenarios: Bool {
    arguments.contains("--interaction-scenarios")
  }

  var closesOnContact: Bool {
    arguments.contains("--close-on-contact")
  }

  var usesPlainHost: Bool {
    arguments.contains("--plain-host")
  }

  var usesRootContainer: Bool {
    arguments.contains("--root-container")
  }

  var usesIntrinsicHost: Bool {
    arguments.contains("--intrinsic-host")
  }

  var usesMagentaRootBackground: Bool {
    arguments.contains("--magenta-root-background")
  }

  var showsDiagnosticActionCount: Bool {
    arguments.contains("--diagnostic-action-count")
  }

  var showsGeometryDiagnostics: Bool {
    arguments.contains("--geometry-diagnostics")
  }

  var usesShortMenu: Bool {
    arguments.contains("--short-menu")
  }

  var usesImageBackground: Bool {
    arguments.contains("--image-background")
  }

  var contentInsets: EdgeInsets {
    EdgeInsets(
      top: arguments.contains("--extra-top-reservation") ? 44 : 0,
      leading: 0, bottom: 0, trailing: 0
    )
  }

  var capturesHeldFrames: Bool {
    arguments.contains("--capture-held-frame")
  }

  var captureStem: String {
    "partial-\(isRightToLeft ? "rtl" : "ltr")-\(edge == .leading ? "leading" : "trailing")"
  }
}

private struct HostGeometryObservation: Equatable {
  let size: CGSize
  let frame: CGRect
  let insets: EdgeInsets
}

/// Only records actual UIKit presentation-layer transforms. Missing presentation
/// layers are counted as unavailable samples; no expected position is substituted.
@MainActor
private final class MenuFrameMeasurement {
  var host: HostGeometryObservation?
  var windowSize = CGSize.zero
  var windowInsets = UIEdgeInsets.zero
  var sampleCount = 0
  var unavailableCount = 0
  var removedCount = 0
  var lastFrame = CGRect.zero
  var openIntermediateCount = 0
  var closedIntermediateCount = 0
  var openMinimumX: CGFloat = 0
  var openMaximumX: CGFloat = 0
  var closedMinimumX: CGFloat = 0
  var closedMaximumX: CGFloat = 0
  var closedOutwardCount = 0
  var closedOutwardDistance: CGFloat = 0
  var closedReversalRange: CGFloat = 0
  var firstReversalFrame: CGRect?
  var maximumFrameJump: CGFloat = 0
  var intervalViolations = 0
  var sampleMinimumX: CGFloat?
  var sampleMaximumX: CGFloat?
  var openingCapture: HeldFrameCapture?
  var closingCapture: HeldFrameCapture?
  var captureFailures = 0
  private var previousPresented: Bool?
  private var lowestInwardPosition: CGFloat?

  func reset() {
    sampleCount = 0
    unavailableCount = 0
    removedCount = 0
    lastFrame = .zero
    openIntermediateCount = 0
    closedIntermediateCount = 0
    openMinimumX = 0
    openMaximumX = 0
    closedMinimumX = 0
    closedMaximumX = 0
    closedOutwardCount = 0
    closedOutwardDistance = 0
    closedReversalRange = 0
    firstReversalFrame = nil
    maximumFrameJump = 0
    intervalViolations = 0
    sampleMinimumX = nil
    sampleMaximumX = nil
    openingCapture = nil
    closingCapture = nil
    captureFailures = 0
    previousPresented = nil
    lowestInwardPosition = nil
  }

  func record(frame: CGRect, isPresented: Bool, opensFromRight: Bool) {
    if sampleCount > 0 {
      let delta = frame.minX - lastFrame.minX
      maximumFrameJump = max(maximumFrameJump, abs(delta))
      if !isPresented && previousPresented == false {
        let inwardDirection: CGFloat = opensFromRight ? -1 : 1
        let inwardDelta = delta * inwardDirection
        let position = frame.minX * inwardDirection
        if inwardDelta < -0.5 {
          closedOutwardCount += 1
          closedOutwardDistance -= inwardDelta
          lowestInwardPosition = min(lowestInwardPosition ?? position, position)
        } else if inwardDelta > 0.5, let lowestInwardPosition {
          if firstReversalFrame == nil { firstReversalFrame = frame }
          closedReversalRange = max(closedReversalRange, position - lowestInwardPosition)
        }
      }
    }
    sampleCount += 1
    lastFrame = frame
    previousPresented = isPresented
    let openX = opensFromRight ? windowSize.width - frame.width : 0
    let closedX = opensFromRight ? windowSize.width : -frame.width
    sampleMinimumX = min(sampleMinimumX ?? frame.minX, frame.minX)
    sampleMaximumX = max(sampleMaximumX ?? frame.minX, frame.minX)
    if frame.minX < min(openX, closedX) - 3 || frame.minX > max(openX, closedX) + 3 {
      intervalViolations += 1
    }
    guard frame.minX > min(openX, closedX) + 3,
      frame.minX < max(openX, closedX) - 3
    else { return }

    if isPresented {
      if openIntermediateCount == 0 {
        openMinimumX = frame.minX
        openMaximumX = frame.minX
      }
      openIntermediateCount += 1
      openMinimumX = min(openMinimumX, frame.minX)
      openMaximumX = max(openMaximumX, frame.minX)
    } else {
      if closedIntermediateCount == 0 {
        closedMinimumX = frame.minX
        closedMaximumX = frame.minX
      }
      closedIntermediateCount += 1
      closedMinimumX = min(closedMinimumX, frame.minX)
      closedMaximumX = max(closedMaximumX, frame.minX)
    }
  }

  func json(isPresented: Bool, contactArmed: Bool, contactActionCount: Int) throws -> String {
    var values: [String: Double] = [
      "actualMenuIntent": isPresented ? 1 : 0,
      "contactArmed": contactArmed ? 1 : 0,
      "contactActionCount": Double(contactActionCount),
      "windowWidth": windowSize.width,
      "windowHeight": windowSize.height,
      "safeTop": windowInsets.top,
      "safeBottom": windowInsets.bottom,
      "safeLeft": windowInsets.left,
      "safeRight": windowInsets.right,
      "hostObserved": host == nil ? 0 : 1,
      "sampleCount": Double(sampleCount),
      "unavailableCount": Double(unavailableCount),
      "removedCount": Double(removedCount),
      "lastX": lastFrame.minX,
      "lastY": lastFrame.minY,
      "lastWidth": lastFrame.width,
      "lastHeight": lastFrame.height,
      "openIntermediateCount": Double(openIntermediateCount),
      "closedIntermediateCount": Double(closedIntermediateCount),
      "openIntermediateRange": openMaximumX - openMinimumX,
      "closedIntermediateRange": closedMaximumX - closedMinimumX,
      "closedOutwardCount": Double(closedOutwardCount),
      "closedOutwardDistance": closedOutwardDistance,
      "closedReversalRange": closedReversalRange,
      "maximumFrameJump": maximumFrameJump,
      "intervalViolations": Double(intervalViolations),
      "openingCaptureCount": openingCapture == nil ? 0 : 1,
      "closingCaptureCount": closingCapture == nil ? 0 : 1,
      "captureFailures": Double(captureFailures),
    ]
    if let host {
      values["hostWidth"] = Double(host.size.width)
      values["hostHeight"] = Double(host.size.height)
      values["hostMinY"] = Double(host.frame.minY)
      values["hostSafeTop"] = Double(host.insets.top)
      values["hostSafeBottom"] = Double(host.insets.bottom)
    }
    if let firstReversalFrame {
      values["firstReversalX"] = Double(firstReversalFrame.minX)
      values["firstReversalMaxX"] = Double(firstReversalFrame.maxX)
      values["firstReversalMinY"] = Double(firstReversalFrame.minY)
      values["firstReversalMaxY"] = Double(firstReversalFrame.maxY)
    }
    if let sampleMinimumX, let sampleMaximumX {
      values["sampleMinX"] = Double(sampleMinimumX)
      values["sampleMaxX"] = Double(sampleMaximumX)
    }
    for (prefix, capture) in [("opening", openingCapture), ("closing", closingCapture)] {
      if let capture {
        values["\(prefix)CaptureX"] = Double(capture.frame.minX)
        for (index, channel) in ["R", "G", "B", "A"].enumerated() {
          values["\(prefix)Panel\(channel)"] = Double(capture.panelRGBA[index])
          values["\(prefix)Outside\(channel)"] = Double(capture.outsideRGBA[index])
        }
      }
    }
    let data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
    return String(decoding: data, as: UTF8.self)
  }
}

private struct NativeMenuFrameProbe: UIViewRepresentable {
  let measurement: MenuFrameMeasurement
  @Binding var isPresented: Bool
  let opensFromRight: Bool
  let capturesHeldFrames: Bool
  let captureStem: String

  func makeUIView(context: Context) -> NativeMenuFrameView {
    NativeMenuFrameView(measurement: measurement, presentationIntent: $isPresented)
  }

  func updateUIView(_ view: NativeMenuFrameView, context: Context) {
    view.presentationIntent = $isPresented
    view.opensFromRight = opensFromRight
    view.capturesHeldFrames = capturesHeldFrames
    view.captureStem = captureStem
  }
}

@MainActor
private final class NativeMenuFrameView: UIView {
  let measurement: MenuFrameMeasurement
  var presentationIntent: Binding<Bool>
  var opensFromRight = false
  var capturesHeldFrames = false
  var captureStem = ""
  private var displayLink: CADisplayLink?
  private let target = FrameDisplayLinkTarget()
  private var wasAttached = false
  private var previousCaptureFrame: CGRect?
  private var stableFrameCount = 0

  init(measurement: MenuFrameMeasurement, presentationIntent: Binding<Bool>) {
    self.measurement = measurement
    self.presentationIntent = presentationIntent
    super.init(frame: .zero)
    isUserInteractionEnabled = false
    target.callback = { [weak self] in self?.sample() }
  }

  required init?(coder: NSCoder) {
    fatalError("Frame probe supports programmatic initialization only")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    displayLink?.invalidate()
    displayLink = nil
    guard window != nil else {
      if wasAttached { measurement.removedCount += 1 }
      wasAttached = false
      return
    }
    wasAttached = true
    let link = CADisplayLink(target: target, selector: #selector(FrameDisplayLinkTarget.tick))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func sample() {
    guard let window else { return }
    measurement.windowSize = window.bounds.size
    measurement.windowInsets = window.safeAreaInsets
    guard let presentation = layer.presentation(),
      let windowPresentation = window.layer.presentation()
    else {
      measurement.unavailableCount += 1
      return
    }
    let frame = presentation.convert(presentation.bounds, to: windowPresentation)
    measurement.record(
      frame: frame,
      isPresented: presentationIntent.wrappedValue,
      opensFromRight: opensFromRight
    )
    captureHeldFrameIfNeeded(window: window, frame: frame)
  }

  private func captureHeldFrameIfNeeded(window: UIWindow, frame: CGRect) {
    guard capturesHeldFrames else { return }
    let visibleWidth = opensFromRight ? window.bounds.width - frame.minX : frame.maxX
    let isHalfVisible = abs(visibleWidth - frame.width * 0.5) <= 3
    if let previousCaptureFrame,
      isHalfVisible && abs(frame.minX - previousCaptureFrame.minX) < 0.5
    {
      stableFrameCount += 1
    } else {
      stableFrameCount = 0
    }
    previousCaptureFrame = frame
    guard isHalfVisible && stableFrameCount >= 5 else { return }
    let isPresented = presentationIntent.wrappedValue
    guard (isPresented ? measurement.closingCapture : measurement.openingCapture) == nil else {
      return
    }

    var didDraw = false
    let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
      didDraw = window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
    }
    do {
      guard didDraw else { throw HeldCaptureError.incompleteHierarchy }
      let panelColumn: CGFloat = opensFromRight ? window.bounds.width - 70 : 70
      let outsideColumn: CGFloat = opensFromRight ? 70 : window.bounds.width - 70
      let capture = HeldFrameCapture(
        frame: frame,
        panelRGBA: try image.rgba(at: CGPoint(x: panelColumn, y: 8)),
        outsideRGBA: try image.rgba(at: CGPoint(x: outsideColumn, y: 8))
      )
      let directory = URL.documentsDirectory.appendingPathComponent("AxiomSideMenu-QA")
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let url = directory.appendingPathComponent(
        "\(captureStem)-\(isPresented ? "closing" : "opening").png")
      guard let data = image.pngData() else { throw HeldCaptureError.missingPixels }
      try data.write(to: url, options: .atomic)
      if isPresented {
        measurement.closingCapture = capture
      } else {
        measurement.openingCapture = capture
      }
      print("AXIOM_HELD_FRAME_PNG \(url.path) nativeX=\(frame.minX)")
    } catch {
      measurement.captureFailures += 1
      print("AXIOM_HELD_FRAME_CAPTURE_FAILED \(error)")
    }
  }
}

private struct HeldFrameCapture {
  let frame: CGRect
  let panelRGBA: [UInt8]
  let outsideRGBA: [UInt8]
}

private enum HeldCaptureError: Error {
  case incompleteHierarchy
  case missingPixels
}

extension UIImage {
  fileprivate func rgba(at point: CGPoint) throws -> [UInt8] {
    guard let source = cgImage else { throw HeldCaptureError.missingPixels }
    let scale = CGFloat(source.width) / size.width
    let bounds = CGRect(
      x: (point.x * scale).rounded(.down), y: (point.y * scale).rounded(.down),
      width: 1, height: 1)
    guard let pixel = source.cropping(to: bounds) else { throw HeldCaptureError.missingPixels }
    var rgba = [UInt8](repeating: 0, count: 4)
    try rgba.withUnsafeMutableBytes { buffer in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      else { throw HeldCaptureError.missingPixels }
      context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    return rgba
  }
}

private struct FrameDiagnosticsLabel: UIViewRepresentable {
  let measurement: MenuFrameMeasurement
  @Binding var isPresented: Bool
  @Binding var contactArmed: Bool
  @Binding var contactActionCount: Int

  func makeUIView(context: Context) -> FrameDiagnosticsLabelView {
    FrameDiagnosticsLabelView(
      measurement: measurement, presentationIntent: $isPresented,
      contactArmed: $contactArmed, contactActionCount: $contactActionCount)
  }

  func updateUIView(_ view: FrameDiagnosticsLabelView, context: Context) {
    view.presentationIntent = $isPresented
    view.contactArmed = $contactArmed
    view.contactActionCount = $contactActionCount
  }
}

@MainActor
private final class FrameDiagnosticsLabelView: UILabel {
  private let measurement: MenuFrameMeasurement
  var presentationIntent: Binding<Bool>
  var contactArmed: Binding<Bool>
  var contactActionCount: Binding<Int>
  private var displayLink: CADisplayLink?
  private let target = FrameDisplayLinkTarget()

  init(
    measurement: MenuFrameMeasurement,
    presentationIntent: Binding<Bool>,
    contactArmed: Binding<Bool>,
    contactActionCount: Binding<Int>
  ) {
    self.measurement = measurement
    self.presentationIntent = presentationIntent
    self.contactArmed = contactArmed
    self.contactActionCount = contactActionCount
    super.init(frame: .zero)
    font = .monospacedSystemFont(ofSize: 8, weight: .regular)
    textAlignment = .center
    isAccessibilityElement = true
    accessibilityIdentifier = "geometry-diagnostics"
    accessibilityLabel = "Real menu frame measurements"
    target.callback = { [weak self] in self?.refresh() }
  }

  required init?(coder: NSCoder) {
    fatalError("Frame diagnostics supports programmatic initialization only")
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    displayLink?.invalidate()
    displayLink = nil
    guard window != nil else { return }
    let link = CADisplayLink(target: target, selector: #selector(FrameDisplayLinkTarget.tick))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func refresh() {
    if let window {
      measurement.windowSize = window.bounds.size
      measurement.windowInsets = window.safeAreaInsets
    }
    text = "Actual menu frame samples: \(measurement.sampleCount)"
    do {
      accessibilityValue = try measurement.json(
        isPresented: presentationIntent.wrappedValue,
        contactArmed: contactArmed.wrappedValue,
        contactActionCount: contactActionCount.wrappedValue)
    } catch {
      accessibilityValue = "Measurement serialization failed: \(error)"
    }
  }
}

@MainActor
private final class FrameDisplayLinkTarget: NSObject {
  var callback: (() -> Void)?

  @objc func tick() {
    callback?()
  }
}
