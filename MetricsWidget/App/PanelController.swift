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
    let clockPreferences = ClockPreferences()
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

    var showUsage: Bool {
        didSet {
            UserDefaults.standard.set(showUsage, forKey: Keys.usage)
            applyVisibility()
        }
    }

    var showClock: Bool {
        didSet {
            UserDefaults.standard.set(showClock, forKey: Keys.clock)
            applyVisibility()
        }
    }

    var openAtLogin: Bool {
        didSet { applyOpenAtLogin() }
    }

    private var networkPanel: GlassPanelWindow?
    private var memoryPanel: GlassPanelWindow?
    private var systemPanel: GlassPanelWindow?
    private var usagePanel: GlassPanelWindow?
    private var clockPanels: [String: GlassPanelWindow] = [:]
    private var settingsWindow: NSWindow?
    private var started = false

    init() {
        IdentityMigration.runIfNeeded()
        let defaults = UserDefaults.standard
        showNetwork = defaults.object(forKey: Keys.network) as? Bool ?? true
        showMemory = defaults.object(forKey: Keys.memory) as? Bool ?? true
        showSystem = defaults.object(forKey: Keys.system) as? Bool ?? true
        showUsage = defaults.object(forKey: Keys.usage) as? Bool ?? true
        showClock = defaults.object(forKey: Keys.clock) as? Bool ?? false
        clockPreferences.reload()
        openAtLogin = SMAppService.mainApp.status == .enabled
    }

    func refreshClockPanels() {
        clockPreferences.reload()
        applyVisibility()
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
                    layout: .network,
                    themeStore: themeStore,
                    shape: .chamferedBottomRight(ChamferedRect.defaultChamfer),
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
                    layout: .memory,
                    themeStore: themeStore,
                    shape: .chamferedBottomRight(ChamferedRect.defaultChamfer),
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
                    layout: .system,
                    themeStore: themeStore,
                    shape: .chamferedBottomRight(ChamferedRect.defaultChamfer),
                    rootView: SystemPanelView(store: store)
                )
            }
            systemPanel?.orderFrontRegardless()
        } else {
            systemPanel?.orderOut(nil)
        }

        if showUsage {
            if usagePanel == nil {
                usagePanel = GlassPanelWindow(
                    id: "usage",
                    layout: .usage,
                    themeStore: themeStore,
                    shape: .chamferedBottomRight(ChamferedRect.defaultChamfer),
                    rootView: UsagePanelView(store: usageStore)
                )
            }
            usagePanel?.orderFrontRegardless()
        } else {
            usagePanel?.orderOut(nil)
        }

        applyClockVisibility()

        store.isActive = showNetwork || showMemory || showSystem
        usageStore.isActive = showUsage
        applyThemeToWindows()
    }

    private func applyThemeToWindows() {
        networkPanel?.applyThemeChrome()
        memoryPanel?.applyThemeChrome()
        systemPanel?.applyThemeChrome()
        usagePanel?.applyThemeChrome()
        for panel in clockPanels.values {
            panel.applyThemeChrome()
        }
    }

    private func applyClockVisibility() {
        let activeIDs = Set(clockPreferences.enabledZones.map(\.panelID))

        if showClock {
            for zone in clockPreferences.enabledZones.sorted(by: { $0.rawValue < $1.rawValue }) {
                let panelID = zone.panelID
                if clockPanels[panelID] == nil {
                    clockPanels[panelID] = GlassPanelWindow(
                        id: panelID,
                        layout: .clock,
                        themeStore: themeStore,
                        shape: .chamferedBottomRight(ChamferedRect.defaultChamfer),
                        clockGlass: true,
                        rootView: ClockPanelView(zone: zone)
                    )
                }
                clockPanels[panelID]?.orderFrontRegardless()
            }
        }

        for (id, panel) in clockPanels {
            if !showClock || !activeIDs.contains(id) {
                panel.orderOut(nil)
            }
        }

        let stale = clockPanels.keys.filter { !activeIDs.contains($0) }
        for id in stale {
            clockPanels[id]?.close()
            clockPanels[id] = nil
        }
    }

    func chooseCustomBackground() {
        if themeStore.installCustomBackgroundFromOpenPanel() {
            themeID = .custom
        }
        applyThemeToWindows()
    }

    func removeCustomBackground() {
        themeStore.removeCustomBackground()
        applyThemeToWindows()
    }

    func openSettings() {
        usagePreferences.reload()
        clockPreferences.reload()
        let root = SettingsView(
            panels: self,
            themes: themeStore,
            preferences: usagePreferences,
            clockPreferences: clockPreferences
        ) { [weak self] in
            self?.usageStore.refreshNow()
        } onClockPreferencesChanged: { [weak self] in
            self?.refreshClockPanels()
        }
        if let settingsWindow {
            settingsWindow.contentViewController = NSHostingController(rootView: root)
        } else {
            let window = NSWindow(contentViewController: NSHostingController(rootView: root))
            window.title = "Metrics Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 520, height: 640))
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
        static let usage = "panel.usage.visible"
        static let clock = "panel.clock.visible"
    }
}
