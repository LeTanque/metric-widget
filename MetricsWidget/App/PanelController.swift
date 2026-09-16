import AppKit
import Observation
import ServiceManagement
import SwiftUI

@MainActor
@Observable
final class PanelController {
    let store = MetricsStore()

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

    var openAtLogin: Bool {
        didSet { applyOpenAtLogin() }
    }

    private var networkPanel: GlassPanelWindow?
    private var memoryPanel: GlassPanelWindow?
    private var systemPanel: GlassPanelWindow?
    private var combinedPanel: GlassPanelWindow?
    private var started = false

    init() {
        let defaults = UserDefaults.standard
        showNetwork = defaults.object(forKey: Keys.network) as? Bool ?? true
        showMemory = defaults.object(forKey: Keys.memory) as? Bool ?? true
        showSystem = defaults.object(forKey: Keys.system) as? Bool ?? true
        showCombined = defaults.object(forKey: Keys.combined) as? Bool ?? false
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
                    size: NSSize(width: 620, height: 400),
                    rootView: CombinedPanelView(store: store)
                )
            }
            combinedPanel?.orderFrontRegardless()
        } else {
            combinedPanel?.orderOut(nil)
        }

        store.isActive = showNetwork || showMemory || showSystem || showCombined
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
    }
}
