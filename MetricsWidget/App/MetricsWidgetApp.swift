import AppKit
import SwiftUI

@main
struct MetricsWidgetApp: App {
    @NSApplicationDelegateAdaptor(MetricsAppDelegate.self) private var appDelegate
    @State private var panels: PanelController = {
        IdentityMigration.runIfNeeded()
        return PanelController()
    }()

    var body: some Scene {
        let _ = { appDelegate.panelController = panels }()
        return MenuBarExtra("Metrics", systemImage: "gauge.with.dots.needle.67percent") {
            Toggle("Network", isOn: $panels.showNetwork)
            Toggle("App Memory", isOn: $panels.showMemory)
            Toggle("CPU, RAM & Storage", isOn: $panels.showSystem)
            Toggle("Usage", isOn: $panels.showUsage)
            Toggle("Clock", isOn: $panels.showClock)
            Divider()
            Picker("Theme", selection: $panels.themeID) {
                ForEach(ThemeID.allCases) { theme in
                    Text(theme.menuTitle).tag(theme)
                }
            }
            Divider()
            Button("Settings…") {
                panels.openSettings()
            }
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
        .onChange(of: panels.showClock) { _, _ in
            panels.start()
        }
    }
}
