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

  @Test
  func restoredSystemInsetsExcludeTheKeyboardInsetsStillPresentInside() {
    let outer = EdgeInsets(top: 62, leading: 0, bottom: 341, trailing: 0)
    let inner = EdgeInsets(top: 0, leading: 0, bottom: 307, trailing: 0)
    #expect(
      SideMenuGeometry.restoredSafeAreaInsets(
        outer: outer, inner: inner, available: CGSize(width: 440, height: 200))
        == EdgeInsets(top: 62, leading: 0, bottom: 34, trailing: 0))
  }

  @Test(
    arguments: [HorizontalEdge.leading, .trailing], [LayoutDirection.leftToRight, .rightToLeft])
  func systemReservationIntersectsThePhysicalPanel(edge: HorizontalEdge, direction: LayoutDirection)
  {
    let isLeftToRight = direction == .leftToRight
    let container = EdgeInsets(
      top: 0, leading: isLeftToRight ? 62 : 18,
      bottom: 21, trailing: isLeftToRight ? 18 : 62)
    let panel = SideMenuGeometry.panelSafeAreaInsets(
      canvas: CGSize(width: 874, height: 402), containerInsets: container,
      panelWidth: 280, edge: edge, layoutDirection: direction)
    let isPhysicalLeft =
      SideMenuGeometry.inwardDirection(edge: edge, layoutDirection: direction) > 0
    let left: CGFloat = isPhysicalLeft ? 62 : 0
    let right: CGFloat = isPhysicalLeft ? 0 : 18
    #expect(
      panel
        == EdgeInsets(
          top: 0, leading: isLeftToRight ? left : right,
          bottom: 21, trailing: isLeftToRight ? right : left))
    #expect(280 - panel.leading - panel.trailing == (isPhysicalLeft ? 218 : 262))
  }

  @Test
  func narrowAndFullWidthPanelsHaveBoundedSystemReservations() {
    let canvas = CGSize(width: 874, height: 402)
    let safe = EdgeInsets(top: 0, leading: 62, bottom: 21, trailing: 18)
    #expect(
      SideMenuGeometry.panelSafeAreaInsets(
        canvas: canvas, containerInsets: safe, panelWidth: 30,
        edge: .leading, layoutDirection: .leftToRight)
        == EdgeInsets(top: 0, leading: 30, bottom: 21, trailing: 0))
    #expect(
      SideMenuGeometry.panelSafeAreaInsets(
        canvas: canvas, containerInsets: safe, panelWidth: .infinity,
        edge: .leading, layoutDirection: .leftToRight) == safe)
    #expect(
      SideMenuGeometry.panelSafeAreaInsets(
        canvas: canvas, containerInsets: safe, panelWidth: 0,
        edge: .leading, layoutDirection: .leftToRight) == EdgeInsets())
  }

  @Test
  func appInsetsAreBoundedAfterTheSystemReservation() {
    let system = EdgeInsets(top: 62, leading: 62, bottom: 34, trailing: 0)
    let requested = EdgeInsets(top: 44, leading: 240, bottom: 900, trailing: 2)
    let layout = SideMenuGeometry.resolvedContentLayout(
      systemInsets: system, contentInsets: requested, available: CGSize(width: 280, height: 874))
    #expect(layout.systemInsets == system)
    #expect(layout.contentInsets == EdgeInsets(top: 44, leading: 218, bottom: 734, trailing: 0))
  }

  @Test
  func zeroSystemReservationPreservesAdvancedModifierSpacing() {
    let requested = EdgeInsets(top: 52, leading: 12, bottom: 8, trailing: 12)
    let available = CGSize(width: 280, height: 800)
    let layout = SideMenuGeometry.resolvedContentLayout(
      systemInsets: .init(), contentInsets: requested, available: available)
    #expect(layout.systemInsets == EdgeInsets())
    #expect(
      layout.contentInsets
        == SideMenuGeometry.resolvedContentInsets(requested: requested, available: available))
  }

  @Test
  func observingNormalizedLayoutKeepsSystemAndAppInsetsDistinct() {
    let top = EdgeInsets(top: 62, leading: 0, bottom: 0, trailing: 0)
    let available = CGSize(width: 280, height: 874)
    let system = SideMenuGeometry.resolvedContentLayout(
      systemInsets: top, contentInsets: .init(), available: available)
    let additional = SideMenuGeometry.resolvedContentLayout(
      systemInsets: .init(), contentInsets: top, available: available)
    #expect(system != additional)
  }
}
