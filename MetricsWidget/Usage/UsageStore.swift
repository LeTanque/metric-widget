import Foundation
import Observation

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshot = UsageSnapshot.empty
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
            openaiEnabled: prefs.openaiEnabled,
            anthropicEnabled: prefs.anthropicEnabled,
            openaiKey: prefs.openaiKey,
            anthropicKey: prefs.anthropicKey
        )
        DispatchQueue.global(qos: .utility).async {
            let next = UsageSampler.sample(preferences: snapshot)
            DispatchQueue.main.async {
                self.snapshot = next
                self.inflight = false
                if self.refreshQueued {
                    self.tick()
                }
            }
        }
    }
}
