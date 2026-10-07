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
    #expect(drag.offset(in: current) == 0)
    #expect(drag.target(in: current, predictedTranslation: -240) == nil)
  }

  @Test
  func externalChangesInvalidateAnInFlightGestureEvenIfBindingReturnsToItsOldValue() {
    let start = context(isPresented: false)
    let drag = SideMenuDragSession(context: start, translation: CGSize(width: 150, height: 0))
    let changed = context(isPresented: false, generation: 2)
    #expect(drag.offset(in: start) == 150)
    #expect(drag.offset(in: changed) == 0)
    #expect(drag.target(in: changed, predictedTranslation: 200) == nil)
  }

  @Test
  func changingWidthOrDirectionInvalidatesTheOriginalTarget() {
    let start = context(isPresented: true)
    let drag = SideMenuDragSession(context: start, translation: CGSize(width: -150, height: 0))
    #expect(
      drag.target(in: context(isPresented: true, width: 240), predictedTranslation: -200) == nil)
    #expect(
      drag.target(in: context(isPresented: true, direction: -1), predictedTranslation: -200) == nil)
  }

  @Test(arguments: [false, true])
  func shortDragPreservesTheCommittedState(isPresented: Bool) {
    let current = context(isPresented: isPresented)
    let translation: CGFloat = isPresented ? -35 : 35
    let drag = SideMenuDragSession(
      context: current, translation: CGSize(width: translation, height: 0))
    #expect(drag.target(in: current, predictedTranslation: translation) == isPresented)
  }

  @Test
  func zeroWidthCannotCommitAnInvisibleDrawer() {
    let current = context(isPresented: false, width: 0)
    let drag = SideMenuDragSession(context: current, translation: CGSize(width: 90, height: 0))
    #expect(drag.offset(in: current) == 0)
    #expect(drag.target(in: current, predictedTranslation: 150) == nil)
    #expect(SideMenuGeometry.resolvedWidth(requested: .infinity, available: 400) == 400)
    #expect(SideMenuGeometry.resolvedWidth(requested: -.infinity, available: 400) == 0)
    #expect(SideMenuGeometry.resolvedWidth(requested: 280, available: .nan) == 0)
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
