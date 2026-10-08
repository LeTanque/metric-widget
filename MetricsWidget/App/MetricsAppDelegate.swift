import AppKit

@MainActor
final class MetricsAppDelegate: NSObject, NSApplicationDelegate {
    weak var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NetworkArcadeFont.register()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        panelController?.openSettings()
        return true
    }
}
