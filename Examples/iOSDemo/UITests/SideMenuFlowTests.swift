import UIKit
import XCTest

@MainActor
final class SideMenuFlowTests: XCTestCase {
  private var primaryButtonFrame = CGRect.zero

  func testNormalModeButtonAndEdgeGestureWithoutDiagnosticFixtures() {
    let app = launch(addDiagnostics: false)
    XCTAssertFalse(app.staticTexts["menu-open-action-count"].exists)
    app.buttons["open-menu"].tap()
    assertHittable(app.buttons["menu-home"])
    app.buttons["menu-home"].tap()
    assertMenuClosed(in: app)

    openByEdgeSwipe(in: app, fromRight: false)
    assertHittable(app.buttons["menu-home"])
    drag(in: app, startX: 240, endX: 20)
    assertMenuClosed(in: app)
  }

  func testHalfWidthThresholdForLeftLeadingMenu() throws {
    try assertHalfWidthThreshold(arguments: [], fromRight: false)
  }

  func testHalfWidthThresholdForRightTrailingMenu() throws {
    try assertHalfWidthThreshold(arguments: ["--trailing"], fromRight: true)
  }

  func testHalfWidthThresholdForRightToLeftLeadingMenu() throws {
    try assertHalfWidthThreshold(arguments: ["--rtl"], fromRight: true)
  }

  func testHalfWidthThresholdForRightToLeftTrailingMenu() throws {
    try assertHalfWidthThreshold(arguments: ["--rtl", "--trailing"], fromRight: false)
  }

  func testNativeFramesProveDirectFollowingAndButtonAnimations() throws {
    let app = launch(arguments: ["--geometry-diagnostics", "--plain-host"])
    app.buttons["reset-main-motion"].tap()
    drag(in: app, startX: 10, endX: 180, holdDuration: 0.4)
    assertMenuOpen(in: app)
    var frames = try frameMeasurement(in: app)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateCount"]), 2)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateRange"]), 20)
    XCTAssertEqual(try XCTUnwrap(frames["lastX"]), 0, accuracy: 3)

    app.buttons["reset-menu-motion"].tap()
    app.buttons["menu-home"].tap()
    assertMenuClosed(in: app)
    frames = try frameMeasurement(in: app)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateCount"]), 2)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateRange"]), 20)
    XCTAssertEqual(try XCTUnwrap(frames["lastX"]), -280, accuracy: 3)
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(frames["removedCount"]), 1)

    app.buttons["reset-main-motion"].tap()
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)
    frames = try frameMeasurement(in: app)
    XCTAssertGreaterThan(try XCTUnwrap(frames["openIntermediateCount"]), 2)
    XCTAssertGreaterThan(try XCTUnwrap(frames["openIntermediateRange"]), 20)
    XCTAssertEqual(try XCTUnwrap(frames["lastX"]), 0, accuracy: 3)

    app.buttons["reset-menu-motion"].tap()
    app.buttons["Close menu"].tap()
    assertMenuClosed(in: app)
    frames = try frameMeasurement(in: app)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateCount"]), 2)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedIntermediateRange"]), 20)
    XCTAssertEqual(try XCTUnwrap(frames["lastX"]), -280, accuracy: 3)
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(frames["removedCount"]), 1)
  }

  func testClosingAnimationCanBeRegrabbedOutsideTheOpeningEdgeZone() throws {
    let app = launch(arguments: ["--geometry-diagnostics", "--interaction-scenarios"])
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)
    app.buttons["reset-menu-motion"].tap()
    app.buttons["schedule-menu-close"].tap()

    let startX: CGFloat = 60
    XCTAssertGreaterThan(startX, 28, "This input must use the panel, not the opening edge zone")
    drag(
      in: app, startX: startX, endX: startX + 170, velocity: 800,
      pressDuration: 2.73, holdDuration: 0.4
    )
    let frames = try frameMeasurement(in: app)
    assertMenuOpen(in: app)
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(frames["closedOutwardCount"]), 1)
    XCTAssertGreaterThan(try XCTUnwrap(frames["closedOutwardDistance"]), 3)
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(frames["closedReversalRange"]), 20)
    let reversalX = try XCTUnwrap(frames["firstReversalX"])
    XCTAssertGreaterThan(reversalX, -277)
    XCTAssertLessThan(reversalX, -3)
    XCTAssertGreaterThan(try XCTUnwrap(frames["firstReversalMaxX"]), startX)
    let inputY = app.frame.height * 0.6
    XCTAssertLessThan(try XCTUnwrap(frames["firstReversalMinY"]), inputY)
    XCTAssertGreaterThan(try XCTUnwrap(frames["firstReversalMaxY"]), inputY)
    XCTAssertLessThan(try XCTUnwrap(frames["maximumFrameJump"]), 80)
    XCTAssertEqual(try XCTUnwrap(frames["lastX"]), 0, accuracy: 3)

    app.buttons["menu-home"].tap()
    assertMenuClosed(in: app)
  }

  func testPlainHostSafeAreaAndBackgroundPixels() throws {
    try assertSafeArea(arguments: ["--plain-host"], fromRight: false, hasBottomControl: true)
  }

  func testShortIntrinsicMenuStartsAtTheSafeTop() throws {
    try assertSafeArea(
      arguments: ["--short-menu", "--trailing"],
      fromRight: true,
      hasBottomControl: false
    )
  }

  func testModalOverlayBlocksThePrimaryButtonAction() {
    let app = launch(arguments: ["--diagnostic-action-count"])
    let openButton = app.buttons["open-menu"]
    let primaryButtonFrame = openButton.frame
    let oppositeButton = app.buttons["outside-action"]
    assertHittable(oppositeButton)
    let oppositeButtonFrame = oppositeButton.frame
    tap(oppositeButtonFrame, in: app)
    XCTAssertEqual(app.staticTexts["outside-action-count"].label, "Opposite edge actions: 1")
    openButton.tap()

    let homeButton = app.buttons["menu-home"]
    let actionCount = app.staticTexts["menu-open-action-count"]
    assertHittable(homeButton)
    XCTAssertEqual(actionCount.label, "Open button actions: 1")

    tap(primaryButtonFrame, in: app)
    XCTAssertEqual(actionCount.label, "Open button actions: 1")
    assertHittable(homeButton)

    homeButton.tap()
    assertMenuClosed(in: app)
    openButton.tap()
    assertHittable(homeButton)
    XCTAssertEqual(actionCount.label, "Open button actions: 2")

    tap(oppositeButtonFrame, in: app)
    assertMenuClosed(in: app)
    XCTAssertEqual(app.staticTexts["outside-action-count"].label, "Opposite edge actions: 1")

    openButton.tap()
    assertHittable(homeButton)
    XCTAssertEqual(actionCount.label, "Open button actions: 3")
    let closeButton = app.buttons["Close menu"]
    assertHittable(closeButton)
    closeButton.tap()
    assertMenuClosed(in: app)
    tap(oppositeButtonFrame, in: app)
    XCTAssertEqual(app.staticTexts["outside-action-count"].label, "Opposite edge actions: 2")
  }

  func testButtonAndEdgeSwipeOpenTheMenuAndScrimClosesIt() {
    let app = launch()
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)

    let scrollView = app.scrollViews["menu-scroll-view"]
    XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
    let lastItem = app.staticTexts["menu-item-20"]
    for _ in 0..<3 where !lastItem.isHittable {
      scrollView.swipeUp()
    }
    assertHittable(lastItem)
    XCTAssertTrue(scrollView.frame.intersects(lastItem.frame))

    dismissOutsideMenu(in: app, fromRight: false)
    assertMenuClosed(in: app)

    openByEdgeSwipe(in: app, fromRight: false)
    assertMenuOpen(in: app)
    dismissOutsideMenu(in: app, fromRight: false)
    assertMenuClosed(in: app)
  }

  func testClosedMenuDoesNotBlockAButtonInsideTheEdgeSwipeRegion() {
    let app = launch()
    let edgeButton = app.buttons["edge-action"]
    assertHittable(edgeButton)
    XCTAssertLessThanOrEqual(edgeButton.frame.midX - app.frame.minX, 28)

    edgeButton.tap()
    XCTAssertEqual(app.staticTexts["edge-tap-count"].label, "Edge taps: 1")
    assertMenuClosed(in: app)
  }

  func testPlainTransparentHostAcceptsAnEdgeSwipe() {
    let app = launch(arguments: ["--plain-host"])
    openByEdgeSwipe(in: app, fromRight: false)
    assertMenuOpen(in: app)

    app.buttons["menu-home"].tap()
    assertMenuClosed(in: app)
    app.buttons["edge-action"].tap()
    XCTAssertEqual(app.staticTexts["edge-tap-count"].label, "Edge taps: 1")
  }

  func testZeroWidthMenuPreservesIntentWithoutBlockingMainContent() {
    let app = launch(arguments: ["--zero-width", "--interaction-scenarios"])
    app.buttons["open-menu"].tap()

    let intent = app.staticTexts["menu-intent"]
    XCTAssertEqual(intent.label, "Menu intent: true")
    XCTAssertFalse(app.buttons["menu-home"].exists)
    XCTAssertFalse(app.buttons["menu-home"].isHittable)
    XCTAssertFalse(app.buttons["Close menu"].exists)
    assertHittable(app.buttons["open-menu"])

    app.buttons["schedule-close"].tap()
    let closedIntent = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", "Menu intent: false"),
      object: intent
    )
    XCTAssertEqual(XCTWaiter.wait(for: [closedIntent], timeout: 5), .completed)
    assertMenuClosed(in: app)
  }

  func testMenuControlsRespectTheTopSafeAreaAndCanCloseTheMenu() throws {
    try assertSafeArea(arguments: [], fromRight: false, hasBottomControl: true)
  }

  func testTrailingMenuOpensFromTheRight() throws {
    try assertDirectionalMenu(arguments: ["--trailing"], fromRight: true)
  }

  func testRightToLeftLeadingMenuOpensFromTheRight() throws {
    try assertDirectionalMenu(arguments: ["--rtl"], fromRight: true)
  }

  func testRightToLeftTrailingMenuOpensFromTheLeft() throws {
    try assertDirectionalMenu(arguments: ["--rtl", "--trailing"], fromRight: false)
  }

  func testShortDragIsRejectedAndLongDragClosesTheMenu() {
    let app = launch()
    drag(in: app, startX: 10, endX: 45, holdDuration: 0.4)
    assertMenuClosed(in: app)

    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)
    app.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: 260, dy: 200))
      .tap()
    assertMenuOpen(in: app)
    drag(in: app, startX: 240, endX: 210, holdDuration: 0.4)
    assertMenuOpen(in: app)

    let outsideX = app.frame.width - 30
    drag(in: app, startX: outsideX, endX: outsideX - 30, holdDuration: 0.4)
    assertMenuOpen(in: app)

    drag(in: app, startX: 240, endX: 20)
    assertMenuClosed(in: app)
  }

  func testSystemSheetDuringAnOpeningDragLeavesMainContentUsable() {
    let app = launch(arguments: ["--interaction-scenarios"])
    app.buttons["schedule-sheet"].tap()

    // The delayed native sheet appears while this short opening drag is held.
    drag(in: app, startX: 10, endX: 45, holdDuration: 3.5)
    assertHittable(app.buttons["dismiss-sheet"])
    app.buttons["dismiss-sheet"].tap()
    assertMenuClosed(in: app)

    app.buttons["edge-action"].tap()
    XCTAssertEqual(app.staticTexts["edge-tap-count"].label, "Edge taps: 1")
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)
  }

  func testExternalBindingChangesDuringDragRemainAuthoritative() {
    let app = launch(arguments: ["--interaction-scenarios"])
    let edgeButtonFrame = app.buttons["edge-action"].frame
    app.buttons["schedule-open"].tap()
    drag(in: app, startX: 10, endX: 45, holdDuration: 3.5)
    assertMenuOpen(in: app)
    dismissOutsideMenu(in: app, fromRight: false)
    assertMenuClosed(in: app)

    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)
    app.buttons["schedule-menu-close"].tap()
    drag(in: app, startX: 240, endX: 210, holdDuration: 3.5)
    assertMenuClosed(in: app)
    tap(edgeButtonFrame, in: app)
    XCTAssertEqual(app.staticTexts["edge-tap-count"].label, "Edge taps: 1")
  }

  private func launch(
    arguments: [String] = [],
    addDiagnostics: Bool = true
  ) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = arguments
    if addDiagnostics && !app.launchArguments.contains("--diagnostic-action-count") {
      app.launchArguments.append("--diagnostic-action-count")
    }
    app.launch()
    assertHittable(app.buttons["open-menu"], timeout: 5)
    XCTAssertGreaterThan(app.frame.width, 390, "The demo must use the iPhone's full screen")
    XCTAssertGreaterThan(app.frame.height, 800, "The demo must use the iPhone's full screen")
    primaryButtonFrame = app.buttons["open-menu"].frame
    return app
  }

  private func assertHalfWidthThreshold(arguments: [String], fromRight: Bool) throws {
    let app = launch(arguments: arguments + ["--geometry-diagnostics", "--capture-held-frame"])
    let inward: CGFloat = fromRight ? -1 : 1
    let openingStart: CGFloat = fromRight ? app.frame.width - 10 : 10
    let closingStart: CGFloat = fromRight ? app.frame.width - 240 : 240

    drag(in: app, startX: openingStart, endX: openingStart + inward * 100, velocity: 1500)
    var frames = try observeRelease(in: app, name: "opening 100pt fast")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight)
    assertMenuClosed(in: app)
    drag(
      in: app, startX: openingStart, endX: openingStart + inward * 140, holdDuration: 0.3)
    frames = try observeRelease(in: app, name: "opening 140pt exact")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight)
    try assertHeldFramePixels(frames, prefix: "opening", fromRight: fromRight)
    assertMenuClosed(in: app)
    drag(in: app, startX: openingStart, endX: openingStart + inward * 170)
    frames = try observeRelease(in: app, name: "opening 170pt")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight, expectsOpen: true)
    assertMenuOpen(in: app)

    drag(in: app, startX: closingStart, endX: closingStart - inward * 100, velocity: 1500)
    frames = try observeRelease(in: app, name: "closing 100pt fast")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight, expectsOpen: true)
    assertMenuOpen(in: app)
    drag(
      in: app, startX: closingStart, endX: closingStart - inward * 140, holdDuration: 0.3)
    frames = try observeRelease(in: app, name: "closing 140pt exact")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight, expectsOpen: true)
    try assertHeldFramePixels(frames, prefix: "closing", fromRight: fromRight)
    assertMenuOpen(in: app)
    drag(in: app, startX: closingStart, endX: closingStart - inward * 170)
    frames = try observeRelease(in: app, name: "closing 170pt")
    try assertPhysicalPanelInterval(frames, fromRight: fromRight)
    assertMenuClosed(in: app)
  }

  private func assertSafeArea(
    arguments: [String],
    fromRight: Bool,
    hasBottomControl: Bool
  ) throws {
    let app = launch(arguments: arguments + ["--geometry-diagnostics"])
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)

    let frames = try frameMeasurement(in: app)
    let safeTop = try XCTUnwrap(frames["safeTop"])
    let safeBottom = try XCTUnwrap(frames["safeBottom"])
    XCTAssertEqual(try XCTUnwrap(frames["hostObserved"]), 1)
    XCTAssertGreaterThan(safeTop, 0)
    XCTAssertGreaterThan(safeBottom, 0)
    XCTAssertGreaterThan(try XCTUnwrap(frames["sampleCount"]), 0)
    XCTAssertEqual(app.staticTexts["menu-open"].frame.minY, safeTop + 16, accuracy: 3)

    if hasBottomControl {
      let bottomButton = app.buttons["menu-bottom"]
      assertHittable(bottomButton)
      XCTAssertEqual(bottomButton.frame.maxY, app.frame.height - safeBottom - 16, accuracy: 3)
    }

    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "Safe-area background and real content boundaries"
    attachment.lifetime = .keepAlways
    add(attachment)
    let column: CGFloat = fromRight ? app.frame.width - 100 : 100
    // Avoid rounded corners, the island, status text/icons, and the home bar.
    try assertMagentaPixel(screenshot, x: column, y: 8)
    try assertMagentaPixel(screenshot, x: column, y: app.frame.height - 8)

    app.buttons["menu-home"].tap()
    assertMenuClosed(in: app)
  }

  private func frameMeasurement(in app: XCUIApplication) throws -> [String: Double] {
    let element = app.staticTexts["geometry-diagnostics"]
    XCTAssertTrue(element.waitForExistence(timeout: 3))
    let json = try XCTUnwrap(element.value as? String)
    print("AXIOM_NATIVE_FRAME_JSON \(json)")
    let attachment = XCTAttachment(string: json)
    attachment.name = "Actual native frames and host proposal"
    attachment.lifetime = .keepAlways
    add(attachment)
    let values = try JSONSerialization.jsonObject(with: Data(json.utf8))
    return try XCTUnwrap(values as? [String: Double])
  }

  private func observeRelease(in app: XCUIApplication, name: String) throws -> [String: Double] {
    let frames = try frameMeasurement(in: app)
    let intent = app.staticTexts["menu-intent"]
    let home = app.buttons["menu-home"]
    let label = intent.exists ? intent.label : "[UNKNOWN: primary label inaccessible]"
    let observation =
      "\(name); intentLabel=\(label); nativeIntent=\(try XCTUnwrap(frames["actualMenuIntent"])); "
      + "home.exists=\(home.exists); home.isHittable=\(home.isHittable)"
    print("AXIOM_RELEASE_OBSERVATION \(observation)")
    let attachment = XCTAttachment(string: observation)
    attachment.name = "Release state and accessibility observation"
    attachment.lifetime = .keepAlways
    add(attachment)
    return frames
  }

  private func assertPhysicalPanelInterval(
    _ frames: [String: Double],
    fromRight: Bool,
    expectsOpen: Bool = false
  ) throws {
    let width = try XCTUnwrap(frames["windowWidth"])
    let minimumX = fromRight ? width - 280 : -280
    let maximumX = fromRight ? width : 0
    XCTAssertGreaterThan(try XCTUnwrap(frames["sampleCount"]), 0)
    XCTAssertEqual(try XCTUnwrap(frames["intervalViolations"]), 0)
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(frames["sampleMinX"]), minimumX - 3)
    XCTAssertLessThanOrEqual(try XCTUnwrap(frames["sampleMaxX"]), maximumX + 3)
    XCTAssertEqual(try XCTUnwrap(frames["lastWidth"]), 280, accuracy: 3)
    if expectsOpen {
      XCTAssertEqual(try XCTUnwrap(frames["lastX"]), fromRight ? width - 280 : 0, accuracy: 3)
    }
  }

  private func assertHeldFramePixels(
    _ frames: [String: Double],
    prefix: String,
    fromRight: Bool
  ) throws {
    XCTAssertEqual(try XCTUnwrap(frames["\(prefix)CaptureCount"]), 1)
    XCTAssertEqual(try XCTUnwrap(frames["captureFailures"]), 0)
    let windowWidth = try XCTUnwrap(frames["windowWidth"])
    let expectedX = fromRight ? windowWidth - 140 : -140
    XCTAssertEqual(try XCTUnwrap(frames["\(prefix)CaptureX"]), expectedX, accuracy: 3)
    XCTAssertGreaterThan(try XCTUnwrap(frames["\(prefix)PanelR"]), 240)
    XCTAssertLessThan(try XCTUnwrap(frames["\(prefix)PanelG"]), 16)
    XCTAssertGreaterThan(try XCTUnwrap(frames["\(prefix)PanelB"]), 240)
    XCTAssertGreaterThan(try XCTUnwrap(frames["\(prefix)PanelA"]), 240)
    let outsideR = try XCTUnwrap(frames["\(prefix)OutsideR"])
    let outsideG = try XCTUnwrap(frames["\(prefix)OutsideG"])
    let outsideB = try XCTUnwrap(frames["\(prefix)OutsideB"])
    XCTAssertLessThan(abs(outsideR - outsideG), 16)
    XCTAssertLessThan(abs(outsideB - outsideG), 16)
    XCTAssertLessThan(max(outsideR, outsideG, outsideB), 210, "The scrim must cover the white gap")
    XCTAssertGreaterThan(try XCTUnwrap(frames["\(prefix)OutsideA"]), 240)
  }

  private func assertMagentaPixel(
    _ screenshot: XCUIScreenshot,
    x: CGFloat,
    y: CGFloat
  ) throws {
    let image = screenshot.image
    let source = try XCTUnwrap(image.cgImage)
    let scale = CGFloat(source.width) / image.size.width
    let pixel = try XCTUnwrap(
      source.cropping(
        to: CGRect(
          x: (x * scale).rounded(.down), y: (y * scale).rounded(.down),
          width: 1, height: 1))
    )
    var rgba = [UInt8](repeating: 0, count: 4)
    try rgba.withUnsafeMutableBytes { buffer in
      let context = try XCTUnwrap(
        CGContext(
          data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
      )
      context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    XCTAssertGreaterThan(rgba[0], 240, "Background pixel at (\(x), \(y)): \(rgba)")
    XCTAssertLessThan(rgba[1], 16, "Background pixel at (\(x), \(y)): \(rgba)")
    XCTAssertGreaterThan(rgba[2], 240, "Background pixel at (\(x), \(y)): \(rgba)")
  }

  private func assertDirectionalMenu(arguments: [String], fromRight: Bool) throws {
    let app = launch(arguments: arguments + ["--geometry-diagnostics"])
    openByEdgeSwipe(in: app, fromRight: fromRight)
    assertMenuOpen(in: app)
    try assertPhysicalPanelInterval(
      try frameMeasurement(in: app), fromRight: fromRight,
      expectsOpen: true)

    let homeButton = app.buttons["menu-home"]
    if fromRight {
      XCTAssertGreaterThan(homeButton.frame.midX, app.frame.maxX - 280)
    } else {
      XCTAssertLessThan(homeButton.frame.midX, app.frame.minX + 280)
    }
    let dragStartX = fromRight ? app.frame.width - 240 : 240
    let dragEndX = fromRight ? app.frame.width - 20 : 20
    drag(in: app, startX: dragStartX, endX: dragEndX)
    try assertPhysicalPanelInterval(try frameMeasurement(in: app), fromRight: fromRight)
    assertMenuClosed(in: app)

    openByEdgeSwipe(in: app, fromRight: fromRight)
    assertMenuOpen(in: app)
    try assertPhysicalPanelInterval(
      try frameMeasurement(in: app), fromRight: fromRight,
      expectsOpen: true)
    dismissOutsideMenu(in: app, fromRight: fromRight)
    assertMenuClosed(in: app)
  }

  private func openByEdgeSwipe(in app: XCUIApplication, fromRight: Bool) {
    let startX = fromRight ? app.frame.width - 10 : 10
    let endX = startX + (fromRight ? -160 : 160)
    drag(in: app, startX: startX, endX: endX)
  }

  private func dismissOutsideMenu(in app: XCUIApplication, fromRight: Bool) {
    let outsideX: CGFloat = fromRight ? 30 : app.frame.width - 30
    app.coordinate(withNormalizedOffset: .zero)
      .withOffset(CGVector(dx: outsideX, dy: app.frame.height * 0.6))
      .tap()
  }

  private func drag(
    in app: XCUIApplication,
    startX: CGFloat,
    endX: CGFloat,
    velocity: CGFloat = 80,
    pressDuration: TimeInterval = 0.05,
    holdDuration: TimeInterval = 0
  ) {
    let origin = app.coordinate(withNormalizedOffset: .zero)
    let y = app.frame.height * 0.6
    let start = origin.withOffset(CGVector(dx: startX, dy: y))
    let end = origin.withOffset(CGVector(dx: endX, dy: y))
    start.press(
      forDuration: pressDuration,
      thenDragTo: end,
      withVelocity: XCUIGestureVelocity(rawValue: velocity),
      thenHoldForDuration: holdDuration
    )
  }

  private func assertMenuOpen(
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let homeButton = app.buttons["menu-home"]
    let actionCount = app.staticTexts["menu-open-action-count"]
    assertHittable(homeButton, file: file, line: line)
    XCTAssertTrue(actionCount.waitForExistence(timeout: 3), file: file, line: line)
    let previousCount = actionCount.label
    XCTAssertTrue(previousCount.hasPrefix("Open button actions: "), file: file, line: line)
    XCTAssertFalse(primaryButtonFrame.isEmpty, file: file, line: line)
    tap(primaryButtonFrame, in: app)
    XCTAssertEqual(actionCount.label, previousCount, file: file, line: line)
    assertHittable(homeButton, file: file, line: line)
  }

  private func tap(_ frame: CGRect, in app: XCUIApplication) {
    app.coordinate(withNormalizedOffset: .zero)
      .withOffset(
        CGVector(
          dx: frame.midX - app.frame.minX,
          dy: frame.midY - app.frame.minY
        )
      )
      .tap()
  }

  private func assertMenuClosed(
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    assertHittable(app.buttons["open-menu"], file: file, line: line)
    XCTAssertFalse(app.buttons["menu-home"].isHittable, file: file, line: line)
  }

  private func assertHittable(
    _ element: XCUIElement,
    timeout: TimeInterval = 3,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "isHittable == true"),
      object: element
    )
    XCTAssertEqual(
      XCTWaiter.wait(for: [expectation], timeout: timeout),
      .completed,
      "Expected \(element) to be visible and hittable",
      file: file,
      line: line
    )
  }
}
