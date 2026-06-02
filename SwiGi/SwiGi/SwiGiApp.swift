import SwiftUI

@main
struct SwiGiApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("SwiGi", systemImage: menuBarIcon) {
            MenuBarContentView(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: String {
        switch appState.engine.status {
        case .running:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .starting:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "exclamationmark.triangle.fill"
        case .stopped:
            return "arrow.triangle.2.circlepath.circle"
        }
    }
}
