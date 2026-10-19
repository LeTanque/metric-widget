import Foundation
import Observation

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshot = UsageSnapshot.empty
    /// Time of each provider's last successful (error-free, configured) fetch, by provider id.
    private(set) var lastSuccess: [String: Date] = [:]
    var isActive = false {
        didSet { syncTimer() }
    }

    private var timer: Timer?
    private var inflight = false
    private var refreshQueued = false

    func refreshNow() {
        refreshQueued = true
        tick()
    }

    private func syncTimer() {
        if isActive {
            refreshQueued = true
            tick()
            guard timer == nil else { return }
            let timer = Timer(timeInterval: 10 * 60, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshQueued = true
                    self?.tick()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        } else {
            timer?.invalidate()
            timer = nil
        }
    }

    private func tick() {
        guard !inflight else { return }
        guard refreshQueued else { return }
        refreshQueued = false
        inflight = true

        let prefs = UsagePreferences()
        let snapshot = UsagePreferencesSnapshot(
            cursorEnabled: prefs.cursorEnabled,
            grokBotEnabled: prefs.grokBotEnabled,
            openaiEnabled: prefs.openaiEnabled,
            anthropicEnabled: prefs.anthropicEnabled,
            openaiKey: prefs.openaiKey,
            anthropicKey: prefs.anthropicKey,
            openaiMonthlyBudget: prefs.openaiMonthlyBudgetValue,
            openaiPlanLimitsEnabled: prefs.openaiPlanLimitsEnabled
        )
        DispatchQueue.global(qos: .utility).async {
            let next = UsageSampler.sample(preferences: snapshot)
            DispatchQueue.main.async {
                self.snapshot = next
                if let stamp = next.lastUpdated {
                    for provider in next.providers where provider.error == nil && provider.subtitle != "Not configured" {
                        self.lastSuccess[provider.id] = stamp
                    }
                }
                self.inflight = false
                if self.refreshQueued {
                    self.tick()
                }
            }
        }
    }
}
