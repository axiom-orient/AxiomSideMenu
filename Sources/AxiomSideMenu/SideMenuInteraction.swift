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
  let recognition: UInt
  private let startingProgress: CGFloat
  private let grabTranslation: CGFloat
  private var translation: CGFloat

  init(
    context: SideMenuDragContext,
    translation: CGSize,
    startingProgress: CGFloat? = nil,
    grabTranslation: CGFloat = 0,
    recognition: UInt = 0
  ) {
    self.context = context
    self.isHorizontal = abs(translation.width) > abs(translation.height)
    self.startingProgress = startingProgress ?? (context.isPresented ? 1 : 0)
    self.grabTranslation = grabTranslation
    self.recognition = recognition
    self.translation = translation.width
  }

  mutating func update(translation: CGSize) {
    self.translation = translation.width
  }

  func progress(in current: SideMenuDragContext) -> CGFloat {
    guard isHorizontal, context.width > 0, context == current else {
      return context.isPresented ? 1 : 0
    }
    let displacement = (translation - grabTranslation) * context.inwardDirection
    return min(1, max(0, startingProgress + displacement / context.width))
  }

  func target(in current: SideMenuDragContext) -> Bool? {
    guard isHorizontal, context.width > 0, context == current else { return nil }
    let finalProgress = progress(in: current)
    if finalProgress > 0.5 { return true }
    if finalProgress < 0.5 { return false }
    return context.isPresented
  }
}

enum SideMenuGeometry {
  static func resolvedWidth(requested: CGFloat, available: CGFloat) -> CGFloat {
    guard !requested.isNaN, available.isFinite, available > 0 else { return 0 }
    return min(max(0, requested), available)
  }

  static func resolvedContentInsets(requested: EdgeInsets, available: CGSize) -> EdgeInsets {
    let width = available.width.isFinite ? max(0, available.width) : 0
    let height = available.height.isFinite ? max(0, available.height) : 0
    func resolve(_ value: CGFloat, limit: CGFloat) -> CGFloat {
      value.isFinite ? min(max(0, value), limit) : 0
    }
    let leading = resolve(requested.leading, limit: width)
    let top = resolve(requested.top, limit: height)
    return EdgeInsets(
      top: top,
      leading: leading,
      bottom: resolve(requested.bottom, limit: height - top),
      trailing: resolve(requested.trailing, limit: width - leading)
    )
  }

  static func inwardDirection(edge: HorizontalEdge, layoutDirection: LayoutDirection) -> CGFloat {
    let isLeftEdge = (edge == .leading) == (layoutDirection == .leftToRight)
    return isLeftEdge ? 1 : -1
  }

  /// SwiftUI mirrors offset presentation with the layout direction. Gesture
  /// coordinates remain physical, so their inward direction must not be reused.
  static func presentationOffset(progress: CGFloat, width: CGFloat, edge: HorizontalEdge)
    -> CGFloat
  {
    let logicalInwardDirection: CGFloat = edge == .leading ? 1 : -1
    return (progress - 1) * width * logicalInwardDirection
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

  static func canDragPanel(
    context: SideMenuDragContext,
    progress: CGFloat,
    isSettling: Bool,
    isRecognizingPanel: Bool,
    isOpeningFromContent: Bool
  ) -> Bool {
    guard context.width > 0, !isOpeningFromContent else { return false }
    return context.isPresented || isRecognizingPanel || (isSettling && progress > 0)
  }

}

/// Local presentation state, independent of the caller's committed binding.
/// Sampling the same curve for rendering and recognition preserves the grab
/// position when a user interrupts a settling animation.
struct SideMenuPresentation: Equatable, Sendable {
  private(set) var progress: CGFloat = 0
  private(set) var motion: SideMenuSettlingMotion?

  func progress(at instant: ContinuousClock.Instant = .now) -> CGFloat {
    motion?.progress(at: instant) ?? progress
  }

  func recognize(
    context: SideMenuDragContext,
    translation: CGSize,
    recognition: UInt,
    at instant: ContinuousClock.Instant = .now
  ) -> SideMenuDragSession {
    let isSettling = motion.map { instant < $0.deadline } ?? false
    return SideMenuDragSession(
      context: context,
      translation: translation,
      startingProgress: progress(at: instant),
      grabTranslation: isSettling ? translation.width : 0,
      recognition: recognition
    )
  }

  mutating func track(_ value: CGFloat) {
    progress = min(1, max(0, value))
    motion = nil
  }

  mutating func settle(
    to isPresented: Bool,
    animated: Bool,
    at instant: ContinuousClock.Instant = .now
  ) {
    let target: CGFloat = isPresented ? 1 : 0
    if animated, motion?.target == target { return }
    let start = progress(at: instant)
    if animated && start != target {
      motion = SideMenuSettlingMotion(start: start, target: target, startedAt: instant)
      progress = target
    } else {
      track(target)
    }
  }

  mutating func finish(_ completed: SideMenuSettlingMotion) {
    guard motion == completed else { return }
    track(completed.target)
  }
}

struct SideMenuSettlingMotion: Equatable, Sendable {
  let start: CGFloat
  let target: CGFloat
  let startedAt: ContinuousClock.Instant
  let duration: Duration = .milliseconds(280)

  var deadline: ContinuousClock.Instant { startedAt.advanced(by: duration) }

  func progress(at instant: ContinuousClock.Instant) -> CGFloat {
    let elapsed = startedAt.duration(to: instant).components
    let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
    let time = min(1, max(0, seconds / 0.28))
    let easedTime = time * time * (3 - 2 * time)
    return start + (target - start) * CGFloat(easedTime)
  }
}
