import AxiomSideMenu
import SwiftUI

struct ContentView: View {
  @Environment(\.layoutDirection) private var systemLayoutDirection

  @State private var isMenuOpen = false
  @State private var openButtonActionCount = 0
  @State private var edgeTapCount = 0
  @State private var oppositeEdgeActionCount = 0
  @State private var isSheetPresented = false
  @State private var scheduledAction: ScheduledAction?

  private let configuration = DemoConfiguration()

  var body: some View {
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
    .sideMenu(isPresented: $isMenuOpen, edge: configuration.edge, width: configuration.width) {
      menuContent
    }
    .environment(
      \.layoutDirection,
      configuration.isRightToLeft ? .rightToLeft : systemLayoutDirection
    )
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

  private var mainContent: some View {
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

      Text("Menu intent: \(isMenuOpen)")
        .accessibilityIdentifier("menu-intent")

      if configuration.showsDiagnosticActionCount {
        Text("Opposite edge actions: \(oppositeEdgeActionCount)")
          .accessibilityIdentifier("outside-action-count")
      }

      if configuration.showsInteractionScenarios {
        interruptionControls
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

  private var menuContent: some View {
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

      if configuration.showsInteractionScenarios {
        Button("Close menu after a delay") {
          scheduledAction = .closeMenu
        }
        .accessibilityIdentifier("schedule-menu-close")
      }

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          ForEach(1...20, id: \.self) { index in
            Text("Menu item \(index)")
              .accessibilityIdentifier("menu-item-\(index)")
          }
        }
      }
      .accessibilityIdentifier("menu-scroll-view")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding()
    .background(.background)
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

  var usesPlainHost: Bool {
    arguments.contains("--plain-host")
  }

  var showsDiagnosticActionCount: Bool {
    arguments.contains("--diagnostic-action-count")
  }
}
