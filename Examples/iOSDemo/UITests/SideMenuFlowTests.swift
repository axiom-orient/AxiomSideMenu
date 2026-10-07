import XCTest

@MainActor
final class SideMenuFlowTests: XCTestCase {
  private var primaryButtonFrame = CGRect.zero

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

  func testMenuControlsRespectTheTopSafeAreaAndCanCloseTheMenu() {
    let app = launch()
    let navigationTop = app.navigationBars.firstMatch.frame.minY
    XCTAssertGreaterThan(navigationTop, app.frame.minY)
    app.buttons["open-menu"].tap()
    assertMenuOpen(in: app)

    let homeButton = app.buttons["menu-home"]
    assertHittable(homeButton)
    XCTAssertGreaterThanOrEqual(homeButton.frame.minY, navigationTop)
    homeButton.tap()
    assertMenuClosed(in: app)
  }

  func testTrailingMenuOpensFromTheRight() {
    assertDirectionalMenu(arguments: ["--trailing"], fromRight: true)
  }

  func testRightToLeftLeadingMenuOpensFromTheRight() {
    assertDirectionalMenu(arguments: ["--rtl"], fromRight: true)
  }

  func testRightToLeftTrailingMenuOpensFromTheLeft() {
    assertDirectionalMenu(arguments: ["--rtl", "--trailing"], fromRight: false)
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

  private func launch(arguments: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = arguments
    if !app.launchArguments.contains("--diagnostic-action-count") {
      app.launchArguments.append("--diagnostic-action-count")
    }
    app.launch()
    assertHittable(app.buttons["open-menu"], timeout: 5)
    XCTAssertGreaterThan(app.frame.width, 390, "The demo must use the iPhone's full screen")
    XCTAssertGreaterThan(app.frame.height, 800, "The demo must use the iPhone's full screen")
    primaryButtonFrame = app.buttons["open-menu"].frame
    return app
  }

  private func assertDirectionalMenu(arguments: [String], fromRight: Bool) {
    let app = launch(arguments: arguments)
    openByEdgeSwipe(in: app, fromRight: fromRight)
    assertMenuOpen(in: app)

    let homeButton = app.buttons["menu-home"]
    if fromRight {
      XCTAssertGreaterThan(homeButton.frame.midX, app.frame.maxX - 280)
    } else {
      XCTAssertLessThan(homeButton.frame.midX, app.frame.minX + 280)
    }
    let dragStartX = fromRight ? app.frame.width - 240 : 240
    let dragEndX = fromRight ? app.frame.width - 20 : 20
    drag(in: app, startX: dragStartX, endX: dragEndX)
    assertMenuClosed(in: app)

    openByEdgeSwipe(in: app, fromRight: fromRight)
    assertMenuOpen(in: app)
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
    holdDuration: TimeInterval = 0
  ) {
    let origin = app.coordinate(withNormalizedOffset: .zero)
    let y = app.frame.height * 0.6
    let start = origin.withOffset(CGVector(dx: startX, dy: y))
    let end = origin.withOffset(CGVector(dx: endX, dy: y))
    start.press(
      forDuration: 0.05,
      thenDragTo: end,
      withVelocity: XCUIGestureVelocity(rawValue: 80),
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
