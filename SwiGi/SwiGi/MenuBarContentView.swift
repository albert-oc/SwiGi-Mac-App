import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    let engine = SwiGiEngine()

    init() {
        engine.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func toggleService() {
        if engine.isRunning {
            engine.stop()
        } else {
            engine.start()
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SwiGi")
                .font(.headline)

            statusView

            Divider()

            Toggle("Verbose logging", isOn: Binding(
                get: { appState.engine.verboseLogging },
                set: { appState.engine.verboseLogging = $0 }
            ))
                .disabled(appState.engine.isRunning)

            Button(appState.engine.isRunning ? "Stop" : "Start") {
                appState.toggleService()
            }
            .keyboardShortcut(.defaultAction)

            Divider()

            Button("Quit SwiGi") {
                appState.engine.stop()
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 280)
    }

    @ViewBuilder
    private var statusView: some View {
        switch appState.engine.status {
        case .stopped:
            Label("Stopped", systemImage: "pause.circle")
                .foregroundStyle(.secondary)
        case .starting:
            Label("Starting…", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)
        case .running(let keyboard, let mouse, let switchCount):
            VStack(alignment: .leading, spacing: 4) {
                Label("Running", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Keyboard: \(keyboard)")
                    .font(.caption)
                    .lineLimit(2)
                Text("Mouse: \(mouse)")
                    .font(.caption)
                    .lineLimit(2)
                Text("Switches: \(switchCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
