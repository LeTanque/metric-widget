import AppKit
import SwiftUI

@main
struct MetricsWidgetApp: App {
    @State private var panels = PanelController()

    var body: some Scene {
        MenuBarExtra("Metrics", systemImage: "gauge.with.dots.needle.67percent") {
            Toggle("Network", isOn: $panels.showNetwork)
            Toggle("App Memory", isOn: $panels.showMemory)
            Toggle("CPU, RAM & Storage", isOn: $panels.showSystem)
            Toggle("All in one", isOn: $panels.showCombined)
            Divider()
            Toggle("Open at Login", isOn: $panels.openAtLogin)
            Divider()
            Button("Quit Metrics") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: panels.showNetwork, initial: true) { _, _ in
            panels.start()
        }
    }
}
