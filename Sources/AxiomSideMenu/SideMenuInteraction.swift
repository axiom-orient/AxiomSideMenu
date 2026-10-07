import SwiftUI

/// The binding and layout at recognition time. A new generation invalidates
/// an in-flight gesture when the caller changes presentation or configuration.
struct SideMenuDragContext: Equatable, Sendable {
  let isPresented: Bool
  let width: CGFloat
  let inwardDirection: CGFloat
  let generation: UInt
}

struct SideMenuDragSession: Equatable, Sendable {
  let context: SideMenuDragContext
  let isHorizontal: Bool
  private var translation: CGFloat

  init(context: SideMenuDragContext, translation: CGSize) {
    self.context = context
    self.isHorizontal = abs(translation.width) > abs(translation.height)
    self.translation = translation.width
  }

  mutating func update(translation: CGSize) {
    self.translation = translation.width
  }

  func offset(in current: SideMenuDragContext) -> CGFloat {
    guard isHorizontal, context.width > 0, context == current else { return 0 }
    return SideMenuGeometry.dragOffset(
      translation: translation,
      isOpen: context.isPresented,
      width: context.width,
      inwardDirection: context.inwardDirection
    )
  }

  func target(in current: SideMenuDragContext, predictedTranslation: CGFloat) -> Bool? {
    guard isHorizontal, context.width > 0, context == current else { return nil }
    let shouldToggle = SideMenuGeometry.shouldToggle(
      translation: translation,
      predictedTranslation: predictedTranslation,
      isOpen: context.isPresented,
      threshold: context.width * 0.3,
      inwardDirection: context.inwardDirection
    )
    return shouldToggle ? !context.isPresented : context.isPresented
  }
}

enum SideMenuGeometry {
  static func resolvedWidth(requested: CGFloat, available: CGFloat) -> CGFloat {
    guard !requested.isNaN, available.isFinite, available > 0 else { return 0 }
    return min(max(0, requested), available)
  }

  static func inwardDirection(edge: HorizontalEdge, layoutDirection: LayoutDirection) -> CGFloat {
    let isLeftEdge = (edge == .leading) == (layoutDirection == .leftToRight)
    return isLeftEdge ? 1 : -1
  }

  static func canStartDrag(
    startX: CGFloat,
    availableWidth: CGFloat,
    context: SideMenuDragContext
  ) -> Bool {
    guard context.width > 0, startX >= 0, startX <= availableWidth else { return false }
    if context.isPresented { return true }
    let distanceFromEdge = context.inwardDirection > 0 ? startX : availableWidth - startX
    return distanceFromEdge <= 28
  }

  static func dragOffset(
    translation: CGFloat,
    isOpen: Bool,
    width: CGFloat,
    inwardDirection: CGFloat
  ) -> CGFloat {
    let distanceTowardCenter = translation * inwardDirection
    let boundedDistance: CGFloat
    if isOpen {
      boundedDistance = max(-width, min(0, distanceTowardCenter))
    } else {
      boundedDistance = min(width, max(0, distanceTowardCenter))
    }
    return boundedDistance * inwardDirection
  }

  static func shouldToggle(
    translation: CGFloat,
    predictedTranslation: CGFloat,
    isOpen: Bool,
    threshold: CGFloat,
    inwardDirection: CGFloat
  ) -> Bool {
    let current = translation * inwardDirection
    let predicted = predictedTranslation * inwardDirection
    let threshold = max(0, threshold)
    if isOpen {
      return min(current, predicted) < -threshold
    }
    return max(current, predicted) > threshold
  }
}
