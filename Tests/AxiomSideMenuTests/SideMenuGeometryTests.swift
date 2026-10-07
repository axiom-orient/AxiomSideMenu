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

  @Test
  func openingDragTracksOnlyMovementTowardTheCenter() {
    #expect(
      SideMenuGeometry.dragOffset(
        translation: 90,
        isOpen: false,
        width: 280,
        inwardDirection: 1
      ) == 90
    )
    #expect(
      SideMenuGeometry.dragOffset(
        translation: -90,
        isOpen: false,
        width: 280,
        inwardDirection: 1
      ) == 0
    )
    #expect(
      SideMenuGeometry.dragOffset(
        translation: -400,
        isOpen: false,
        width: 280,
        inwardDirection: -1
      ) == -280
    )
  }

  @Test
  func closingDragTracksOnlyMovementAwayFromTheCenter() {
    #expect(
      SideMenuGeometry.dragOffset(
        translation: -90,
        isOpen: true,
        width: 280,
        inwardDirection: 1
      ) == -90
    )
    #expect(
      SideMenuGeometry.dragOffset(
        translation: 90,
        isOpen: true,
        width: 280,
        inwardDirection: 1
      ) == 0
    )
    #expect(
      SideMenuGeometry.dragOffset(
        translation: 400,
        isOpen: true,
        width: 280,
        inwardDirection: -1
      ) == 280
    )
  }

  @Test
  func predictedDragDistanceCanOpenOrCloseTheMenu() {
    #expect(
      SideMenuGeometry.shouldToggle(
        translation: 35,
        predictedTranslation: 100,
        isOpen: false,
        threshold: 84,
        inwardDirection: 1
      )
    )
    #expect(
      SideMenuGeometry.shouldToggle(
        translation: -40,
        predictedTranslation: -100,
        isOpen: true,
        threshold: 84,
        inwardDirection: 1
      )
    )
    #expect(
      !SideMenuGeometry.shouldToggle(
        translation: 40,
        predictedTranslation: 50,
        isOpen: false,
        threshold: 84,
        inwardDirection: 1
      )
    )
  }
}
