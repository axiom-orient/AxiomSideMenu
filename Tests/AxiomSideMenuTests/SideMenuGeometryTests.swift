import SwiftUI
import Testing

@testable import AxiomSideMenu

struct SideMenuGeometryTests {
  @Test
  func menuWidthStaysInsideAvailableSpace() {
    #expect(SideMenuGeometry.resolvedWidth(requested: 280, available: 400) == 280)
    #expect(SideMenuGeometry.resolvedWidth(requested: 500, available: 400) == 400)
    #expect(SideMenuGeometry.resolvedWidth(requested: -20, available: 400) == 0)
    #expect(SideMenuGeometry.resolvedWidth(requested: .nan, available: 400) == 0)
  }

  @Test(arguments: [false, true], [CGFloat(-1), CGFloat(1)])
  func liveProgressStaysInsideThePanel(isPresented: Bool, direction: CGFloat) {
    let context = SideMenuDragContext(
      isPresented: isPresented, width: 280, inwardDirection: direction, generation: 0)
    let fullOpening = SideMenuDragSession(
      context: context, translation: CGSize(width: 400 * direction, height: 0))
    let fullClosing = SideMenuDragSession(
      context: context, translation: CGSize(width: -400 * direction, height: 0))
    #expect(fullOpening.progress(in: context) == 1)
    #expect(fullClosing.progress(in: context) == 0)
  }

  @Test(arguments: [CGFloat(-1), CGFloat(1)])
  func shortActualMovementCannotOpenTheMenu(direction: CGFloat) {
    let context = SideMenuDragContext(
      isPresented: false, width: 280, inwardDirection: direction, generation: 0)
    let session = SideMenuDragSession(
      context: context, translation: CGSize(width: 40 * direction, height: 0))
    #expect(session.target(in: context) == false)
  }

  @Test
  func presentationOffsetsUseLogicalEdgesBeforeSwiftUIMirrorsThem() {
    #expect(SideMenuGeometry.presentationOffset(progress: 0, width: 280, edge: .leading) == -280)
    #expect(SideMenuGeometry.presentationOffset(progress: 0, width: 280, edge: .trailing) == 280)
    #expect(SideMenuGeometry.presentationOffset(progress: 0.5, width: 280, edge: .leading) == -140)
    #expect(SideMenuGeometry.presentationOffset(progress: 0.5, width: 280, edge: .trailing) == 140)
    #expect(SideMenuGeometry.presentationOffset(progress: 1, width: 280, edge: .leading) == 0)
    #expect(SideMenuGeometry.presentationOffset(progress: 1, width: 280, edge: .trailing) == 0)
  }

  @Test
  func rightToLeftGestureDirectionsStayPhysicalAndSeparateFromPresentation() {
    #expect(SideMenuGeometry.inwardDirection(edge: .leading, layoutDirection: .rightToLeft) == -1)
    #expect(SideMenuGeometry.inwardDirection(edge: .trailing, layoutDirection: .rightToLeft) == 1)
    #expect(SideMenuGeometry.presentationOffset(progress: 0.5, width: 280, edge: .leading) < 0)
    #expect(SideMenuGeometry.presentationOffset(progress: 0.5, width: 280, edge: .trailing) > 0)
  }

  @Test
  func contentInsetsReserveOnlyTheirAdditionalRequestedSpace() {
    let requested = EdgeInsets(top: 52, leading: 12, bottom: 8, trailing: 14)
    #expect(
      SideMenuGeometry.resolvedContentInsets(
        requested: requested, available: CGSize(width: 280, height: 800)) == requested)
  }

  @Test
  func contentInsetsCannotProduceNegativeOrNonFiniteLayout() {
    let requested = EdgeInsets(top: .nan, leading: -20, bottom: .infinity, trailing: -.infinity)
    let available = CGSize(width: 280, height: 800)
    let first = SideMenuGeometry.resolvedContentInsets(requested: requested, available: available)
    let second = SideMenuGeometry.resolvedContentInsets(requested: requested, available: available)
    #expect(first == second)
    #expect(
      SideMenuGeometry.resolvedContentInsets(
        requested: requested, available: available) == EdgeInsets())
  }

  @Test
  func oversizedInsetsFitTheOfferedContentRegion() {
    let requested = EdgeInsets(top: 700, leading: 250, bottom: 200, trailing: 100)
    #expect(
      SideMenuGeometry.resolvedContentInsets(
        requested: requested, available: CGSize(width: 280, height: 800))
        == EdgeInsets(top: 700, leading: 250, bottom: 100, trailing: 30))
    #expect(
      SideMenuGeometry.resolvedContentInsets(
        requested: requested, available: CGSize(width: .nan, height: -.infinity)) == EdgeInsets())
  }
}
