import SwiftUI
import Testing

@testable import AxiomSideMenu

struct SideMenuInteractionTests {
  @Test
  func edgeAdmissionUsesStableHostCoordinates() {
    let left = context(isPresented: false, direction: 1)
    let right = context(isPresented: false, direction: -1)
    #expect(SideMenuGeometry.canStartDrag(startX: 10, availableWidth: 400, context: left))
    #expect(!SideMenuGeometry.canStartDrag(startX: 390, availableWidth: 400, context: left))
    #expect(SideMenuGeometry.canStartDrag(startX: 390, availableWidth: 400, context: right))
    #expect(!SideMenuGeometry.canStartDrag(startX: 10, availableWidth: 400, context: right))
    #expect(!SideMenuGeometry.canStartDrag(startX: -1, availableWidth: 400, context: left))
  }

  @Test
  func logicalEdgesFollowLayoutDirection() {
    #expect(SideMenuGeometry.inwardDirection(edge: .leading, layoutDirection: .leftToRight) == 1)
    #expect(SideMenuGeometry.inwardDirection(edge: .trailing, layoutDirection: .leftToRight) == -1)
    #expect(SideMenuGeometry.inwardDirection(edge: .leading, layoutDirection: .rightToLeft) == -1)
    #expect(SideMenuGeometry.inwardDirection(edge: .trailing, layoutDirection: .rightToLeft) == 1)
  }

  @Test
  func verticalRecognitionDoesNotBecomeADrawerGestureLater() {
    let current = context(isPresented: true)
    var drag = SideMenuDragSession(
      context: current,
      translation: CGSize(width: -2, height: 12)
    )
    drag.update(translation: CGSize(width: -200, height: 15))
    #expect(drag.progress(in: current) == 1)
    #expect(drag.target(in: current) == nil)
  }

  @Test
  func externalChangesInvalidateAnInFlightGestureEvenIfBindingReturnsToItsOldValue() {
    let start = context(isPresented: false)
    let drag = SideMenuDragSession(context: start, translation: CGSize(width: 150, height: 0))
    let changed = context(isPresented: false, generation: 2)
    #expect(drag.progress(in: start) == 150.0 / 280)
    #expect(drag.progress(in: changed) == 0)
    #expect(drag.target(in: changed) == nil)
  }

  @Test
  func changingWidthOrDirectionInvalidatesTheOriginalTarget() {
    let start = context(isPresented: true)
    let drag = SideMenuDragSession(context: start, translation: CGSize(width: -150, height: 0))
    #expect(
      drag.target(in: context(isPresented: true, width: 240)) == nil)
    #expect(
      drag.target(in: context(isPresented: true, direction: -1)) == nil)
  }

  @Test(arguments: [false, true])
  func shortDragPreservesTheCommittedState(isPresented: Bool) {
    let current = context(isPresented: isPresented)
    let translation: CGFloat = isPresented ? -35 : 35
    let drag = SideMenuDragSession(
      context: current, translation: CGSize(width: translation, height: 0))
    #expect(drag.target(in: current) == isPresented)
  }

  @Test
  func zeroWidthCannotCommitAnInvisibleDrawer() {
    let current = context(isPresented: false, width: 0)
    let drag = SideMenuDragSession(context: current, translation: CGSize(width: 90, height: 0))
    #expect(drag.progress(in: current) == 0)
    #expect(drag.target(in: current) == nil)
    #expect(SideMenuGeometry.resolvedWidth(requested: .infinity, available: 400) == 400)
    #expect(SideMenuGeometry.resolvedWidth(requested: -.infinity, available: 400) == 0)
    #expect(SideMenuGeometry.resolvedWidth(requested: 280, available: .nan) == 0)
  }

  @Test(arguments: [false, true], [CGFloat(-1), CGFloat(1)])
  func halfWidthIsStrictForBothDirections(isPresented: Bool, direction: CGFloat) {
    let current = context(isPresented: isPresented, direction: direction)
    let movementDirection = isPresented ? -direction : direction
    for (distance, toggles) in [(CGFloat(139), false), (140, false), (140.001, true)] {
      let session = SideMenuDragSession(
        context: current,
        translation: CGSize(width: distance * movementDirection, height: 0)
      )
      #expect(session.target(in: current) == (toggles ? !isPresented : isPresented))
    }
  }

  @Test(arguments: [false, true], [CGFloat(-1), CGFloat(1)])
  func reversalUsesTheReleasedDisplacement(isPresented: Bool, direction: CGFloat) {
    let current = context(isPresented: isPresented, direction: direction)
    let movementDirection = isPresented ? -direction : direction
    var session = SideMenuDragSession(
      context: current,
      translation: CGSize(width: 170 * movementDirection, height: 0)
    )
    #expect(session.target(in: current) == !isPresented)
    session.update(translation: CGSize(width: 100 * movementDirection, height: 0))
    #expect(session.target(in: current) == isPresented)
  }

  @Test
  func presentationFollowsOpeningAndClosingDisplacement() {
    let closed = context(isPresented: false)
    let opening = SideMenuDragSession(
      context: closed, translation: CGSize(width: 70, height: 0))
    #expect(opening.progress(in: closed) == 0.25)

    let open = context(isPresented: true)
    let closing = SideMenuDragSession(
      context: open, translation: CGSize(width: -70, height: 0))
    #expect(closing.progress(in: open) == 0.75)
  }

  @Test
  func grabbingAnAnimationKeepsItsCurrentPosition() {
    let current = context(isPresented: false)
    var session = SideMenuDragSession(
      context: current,
      translation: CGSize(width: 10, height: 0),
      startingProgress: 0.6,
      grabTranslation: 10
    )
    #expect(session.progress(in: current) == 0.6)
    session.update(translation: CGSize(width: 38, height: 0))
    #expect(abs(session.progress(in: current) - 0.7) < 0.0001)
    #expect(session.target(in: current) == true)
  }

  @Test
  func settledRecognitionKeepsTheFullFingerDisplacement() {
    let current = context(isPresented: false)
    let presentation = SideMenuPresentation()
    var session = presentation.recognize(
      context: current, translation: CGSize(width: 20, height: 0), recognition: 1)
    #expect(session.progress(in: current) == 20.0 / 280)
    session.update(translation: CGSize(width: 140, height: 0))
    #expect(session.progress(in: current) == 0.5)
    #expect(session.target(in: current) == false)
    session.update(translation: CGSize(width: 150, height: 0))
    #expect(session.target(in: current) == true)
  }

  @Test
  func onlyAnActiveSettleUsesARecognitionGrabOffset() {
    let start = ContinuousClock.now
    var presentation = SideMenuPresentation()
    presentation.settle(to: true, animated: true, at: start)
    let halfway = start.advanced(by: .milliseconds(140))
    let closed = context(isPresented: false)
    var regrab = presentation.recognize(
      context: closed, translation: CGSize(width: 20, height: 0), recognition: 1, at: halfway)
    #expect(regrab.progress(in: closed) == 0.5)
    regrab.update(translation: CGSize(width: 48, height: 0))
    #expect(regrab.progress(in: closed) == 0.6)
    #expect(regrab.target(in: closed) == true)

    // A delayed completion task must not add a dead zone once the curve ended.
    let open = context(isPresented: true)
    let settled = presentation.recognize(
      context: open,
      translation: CGSize(width: -20, height: 0),
      recognition: 2,
      at: start.advanced(by: .milliseconds(280))
    )
    #expect(settled.progress(in: open) == 1 - 20.0 / 280)
  }

  @Test(arguments: [false, true])
  func halfwayRegrabRetainsTheGestureStartingBinding(isPresented: Bool) {
    let current = context(isPresented: isPresented)
    let session = SideMenuDragSession(
      context: current,
      translation: CGSize(width: 70, height: 0),
      startingProgress: 0.25
    )
    #expect(session.progress(in: current) == 0.5)
    #expect(session.target(in: current) == isPresented)
  }

  @Test
  func retargetingASettleStartsAtItsCurrentPosition() throws {
    let start = ContinuousClock.now
    let halfway = start.advanced(by: .milliseconds(140))
    var presentation = SideMenuPresentation()
    presentation.settle(to: true, animated: true, at: start)
    let previousMotion = try #require(presentation.motion)
    #expect(presentation.progress(at: halfway) == 0.5)

    presentation.settle(to: false, animated: true, at: halfway)
    #expect(presentation.progress(at: halfway) == 0.5)
    #expect(presentation.progress(at: halfway.advanced(by: .milliseconds(140))) == 0.25)
    presentation.finish(previousMotion)
    #expect(presentation.motion?.target == 0)
  }

  @Test
  func trackingStopsThePreviousAnimationAndRejectsItsLateCompletion() throws {
    let start = ContinuousClock.now
    var presentation = SideMenuPresentation()
    presentation.settle(to: true, animated: true, at: start)
    let oldMotion = try #require(presentation.motion)
    presentation.track(0.4)
    presentation.finish(oldMotion)
    #expect(presentation.progress == 0.4)
    #expect(presentation.motion == nil)
  }

  @Test
  func nonAnimatedSettlesSnapToTheAuthoritativeBinding() {
    var presentation = SideMenuPresentation()
    presentation.track(0.4)
    presentation.settle(to: true, animated: false)
    #expect(presentation.progress == 1)
    #expect(presentation.motion == nil)
    presentation.settle(to: false, animated: false)
    #expect(presentation.progress == 0)
  }

  @Test
  func closingPanelCanBeGrabbedWhileItsCommittedBindingIsFalse() {
    let current = context(isPresented: false)
    #expect(
      SideMenuGeometry.canDragPanel(
        context: current, progress: 0.7, isSettling: true,
        isRecognizingPanel: false, isOpeningFromContent: false))
    #expect(
      !SideMenuGeometry.canDragPanel(
        context: current, progress: 0, isSettling: true,
        isRecognizingPanel: false, isOpeningFromContent: false))
  }

  @Test
  func activePanelRecognitionSurvivesTheFullyHiddenPosition() {
    #expect(
      SideMenuGeometry.canDragPanel(
        context: context(isPresented: false), progress: 0, isSettling: false,
        isRecognizingPanel: true, isOpeningFromContent: false))
  }

  @Test
  func panelGestureCannotTakeOverTheOriginalOpeningPreview() {
    #expect(
      !SideMenuGeometry.canDragPanel(
        context: context(isPresented: false), progress: 0.7, isSettling: false,
        isRecognizingPanel: false, isOpeningFromContent: true))
  }

  @Test
  func resettingPresentationDoesNotDiscardAStillValidReleaseSnapshot() {
    let current = context(isPresented: false)
    let session = SideMenuDragSession(
      context: current, translation: CGSize(width: 170, height: 0))
    var presentation = SideMenuPresentation()
    presentation.track(session.progress(in: current))
    presentation.settle(to: current.isPresented, animated: true)
    #expect(session.target(in: current) == true)
    #expect(session.target(in: context(isPresented: false, generation: 1)) == nil)
  }

  private func context(
    isPresented: Bool,
    width: CGFloat = 280,
    direction: CGFloat = 1,
    generation: UInt = 0
  ) -> SideMenuDragContext {
    SideMenuDragContext(
      isPresented: isPresented,
      width: width,
      inwardDirection: direction,
      generation: generation
    )
  }
}
