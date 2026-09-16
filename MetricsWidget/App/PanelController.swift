import AppKit
import Observation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
final class PanelController {
    let store = MetricsStore()
    let usageStore = UsageStore()
    let usagePreferences = UsagePreferences()
    let themeStore = ThemeStore()

    var themeID: ThemeID {
        get { themeStore.id }
        set {
            themeStore.id = newValue
            applyThemeToWindows()
        }
    }

    var showNetwork: Bool {
        didSet {
            UserDefaults.standard.set(showNetwork, forKey: Keys.network)
            applyVisibility()
        }
    }

    var showMemory: Bool {
        didSet {
            UserDefaults.standard.set(showMemory, forKey: Keys.memory)
            applyVisibility()
        }
    }

    var showSystem: Bool {
        didSet {
            UserDefaults.standard.set(showSystem, forKey: Keys.system)
            applyVisibility()
        }
    }

    var showCombined: Bool {
        didSet {
            UserDefaults.standard.set(showCombined, forKey: Keys.combined)
            applyVisibility()
        }
    }

    var showUsage: Bool {
        didSet {
            UserDefaults.standard.set(showUsage, forKey: Keys.usage)
            applyVisibility()
        }
    }

    var openAtLogin: Bool {
        didSet { applyOpenAtLogin() }
    }

    private var networkPanel: GlassPanelWindow?
    private var memoryPanel: GlassPanelWindow?
    private var systemPanel: GlassPanelWindow?
    private var combinedPanel: GlassPanelWindow?
    private var usagePanel: GlassPanelWindow?
    private var settingsWindow: NSWindow?
    private var started = false

    init() {
        let defaults = UserDefaults.standard
        showNetwork = defaults.object(forKey: Keys.network) as? Bool ?? true
        showMemory = defaults.object(forKey: Keys.memory) as? Bool ?? true
        showSystem = defaults.object(forKey: Keys.system) as? Bool ?? true
        showCombined = defaults.object(forKey: Keys.combined) as? Bool ?? false
        showUsage = defaults.object(forKey: Keys.usage) as? Bool ?? true
        openAtLogin = SMAppService.mainApp.status == .enabled
    }

    func start() {
        guard !started else {
            applyVisibility()
            return
        }
        started = true
        applyVisibility()
    }

    private func applyVisibility() {
        if showNetwork {
            if networkPanel == nil {
                networkPanel = GlassPanelWindow(
                    id: "network",
                    size: NSSize(width: 332, height: 228),
                    themeStore: themeStore,
                    rootView: NetworkPanelView(store: store)
                )
            }
            networkPanel?.orderFrontRegardless()
        } else {
            networkPanel?.orderOut(nil)
        }

        if showMemory {
            if memoryPanel == nil {
                memoryPanel = GlassPanelWindow(
                    id: "memory",
                    size: NSSize(width: 292, height: 268),
                    themeStore: themeStore,
                    rootView: AppMemoryPanelView(store: store)
                )
            }
            memoryPanel?.orderFrontRegardless()
        } else {
            memoryPanel?.orderOut(nil)
        }

        if showSystem {
            if systemPanel == nil {
                systemPanel = GlassPanelWindow(
                    id: "system",
                    size: NSSize(width: 300, height: 248),
                    themeStore: themeStore,
                    rootView: SystemPanelView(store: store)
                )
            }
            systemPanel?.orderFrontRegardless()
        } else {
            systemPanel?.orderOut(nil)
        }

        if showCombined {
            if combinedPanel == nil {
                combinedPanel = GlassPanelWindow(
                    id: "combined",
                    size: NSSize(width: 640, height: 468),
                    themeStore: themeStore,
                    rootView: CombinedPanelView(store: store, usageStore: usageStore)
                )
            }
            combinedPanel?.orderFrontRegardless()
        } else {
            combinedPanel?.orderOut(nil)
        }

        if showUsage {
            if usagePanel == nil {
                usagePanel = GlassPanelWindow(
                    id: "usage",
                    size: NSSize(width: 340, height: 300),
                    themeStore: themeStore,
                    rootView: UsagePanelView(store: usageStore)
                )
            }
            usagePanel?.orderFrontRegardless()
        } else {
            usagePanel?.orderOut(nil)
        }

        store.isActive = showNetwork || showMemory || showSystem || showCombined
        usageStore.isActive = showUsage || showCombined
        applyThemeToWindows()
    }

    private func applyThemeToWindows() {
        networkPanel?.applyThemeChrome()
        memoryPanel?.applyThemeChrome()
        systemPanel?.applyThemeChrome()
        combinedPanel?.applyThemeChrome()
        usagePanel?.applyThemeChrome()
    }

    func openSettings() {
        usagePreferences.reload()
        let root = SettingsView(
            preferences: usagePreferences,
            usagePanelVisible: showUsage || showCombined
        ) { [weak self] in
            self?.usageStore.refreshNow()
        }
        if let settingsWindow {
            settingsWindow.contentViewController = NSHostingController(rootView: root)
        } else {
            let window = NSWindow(contentViewController: NSHostingController(rootView: root))
            window.title = "Metrics Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 520, height: 520))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func applyOpenAtLogin() {
        let enabled = SMAppService.mainApp.status == .enabled
        guard openAtLogin != enabled else { return }
        do {
            if openAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            openAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private enum Keys {
        static let network = "panel.network.visible"
        static let memory = "panel.memory.visible"
        static let system = "panel.system.visible"
        static let combined = "panel.combined.visible"
        static let usage = "panel.usage.visible"
    }
}
