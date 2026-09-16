import Foundation
import Observation

@MainActor
@Observable
final class MetricsStore {
    private(set) var snapshot = MetricsSnapshot.empty

    var isActive = false {
        didSet { syncTimer() }
    }

    private let sampler = Sampler()
    private var timer: Timer?

    private func syncTimer() {
        if isActive {
            guard timer == nil else { return }
            snapshot = sampler.sample()
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in
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
        snapshot = sampler.sample()
    }
}
