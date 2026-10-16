import Foundation
import Observation
import os

@MainActor
@Observable
final class ProviderStatusStore {
    struct Line: Identifiable, Equatable {
        var id: StatusProvider
        var name: String
        var dot: String
        var text: String
    }

    private(set) var lines: [Line] = []

    var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: Keys.enabled)
            sync()
        }
    }

    /// True while the Usage tile is visible.
    var isActive = false {
        didSet { sync() }
    }

    private var readings: [StatusProvider: ProviderStatusReading] = [:]
    private var nextDue: [StatusProvider: Date] = [:]
    private var inflight: Set<StatusProvider> = []
    private var polled: [StatusProvider] = []
    private var timer: Timer?
    private let log = Logger(subsystem: "com.metricswidget.app", category: "status")

    init() {
        enabled = UserDefaults.standard.object(forKey: Keys.enabled) as? Bool ?? true
    }

    /// Re-read provider toggles (e.g. after Settings save).
    func refreshEnabled() {
        sync()
    }

    private var isRunning: Bool { enabled && isActive }

    private func sync() {
        guard isRunning else {
            timer?.invalidate()
            timer = nil
            polled = []
            nextDue = [:]
            rebuildLines()
            return
        }

        let current = StatusProvider.allCases.filter(\.isUsageEnabled)
        for provider in current where !polled.contains(provider) {
            nextDue[provider] = .distantPast
        }
        for provider in polled where !current.contains(provider) {
            nextDue[provider] = nil
            log.notice("status stop \(provider.rawValue, privacy: .public) (provider disabled)")
        }
        polled = current

        if timer == nil {
            let timer = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.sync() }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }

        let now = Date()
        for provider in polled where !inflight.contains(provider) {
            if let due = nextDue[provider], due <= now {
                fetch(provider)
            }
        }
        rebuildLines()
    }

    private func fetch(_ provider: StatusProvider) {
        inflight.insert(provider)
        log.notice("status fetch \(provider.rawValue, privacy: .public)")
        DispatchQueue.global(qos: .utility).async {
            let reading = ProviderStatusClient.fetch(provider)
            DispatchQueue.main.async {
                self.apply(reading, for: provider)
            }
        }
    }

    private func apply(_ reading: ProviderStatusReading, for provider: StatusProvider) {
        inflight.remove(provider)
        guard isRunning, polled.contains(provider) else { return }

        let defaults = UserDefaults.standard
        var levels = defaults.dictionary(forKey: Keys.lastLevel) as? [String: String] ?? [:]
        let previous = levels[provider.rawValue].flatMap(StatusLevel.init(rawValue:))

        if reading.level == .operational {
            var phrases = defaults.dictionary(forKey: Keys.greenPhrase) as? [String: String] ?? [:]
            var days = defaults.dictionary(forKey: Keys.greenDay) as? [String: String] ?? [:]
            let stored = phrases[provider.rawValue].flatMap { phrase in
                days[provider.rawValue].map { GreenPhrase.Pick(phrase: phrase, day: $0) }
            }
            let pick = GreenPhrase.resolve(previous: previous, stored: stored, today: GreenPhrase.dayKey())
            if pick != stored {
                phrases[provider.rawValue] = pick.phrase
                days[provider.rawValue] = pick.day
                defaults.set(phrases, forKey: Keys.greenPhrase)
                defaults.set(days, forKey: Keys.greenDay)
                log.notice("status phrase \(provider.rawValue, privacy: .public) rerolled")
            }
        }
        levels[provider.rawValue] = reading.level.rawValue
        defaults.set(levels, forKey: Keys.lastLevel)

        readings[provider] = reading
        nextDue[provider] = Date().addingTimeInterval(reading.level.pollInterval)
        log.notice("status result \(provider.rawValue, privacy: .public) \(reading.level.rawValue, privacy: .public) next \(Int(reading.level.pollInterval / 60), privacy: .public)m")
        rebuildLines()
    }

    private func rebuildLines() {
        guard enabled else {
            if !lines.isEmpty { lines = [] }
            return
        }
        let phrases = UserDefaults.standard.dictionary(forKey: Keys.greenPhrase) as? [String: String] ?? [:]
        let providers = isActive ? polled : StatusProvider.allCases.filter(\.isUsageEnabled)
        let next = providers.map { provider -> Line in
            let reading = readings[provider] ?? .unavailable
            let text: String
            switch reading.level {
            case .unavailable: text = "Status unavailable"
            case .operational: text = phrases[provider.rawValue].flatMap { GreenPhrase.all.contains($0) ? $0 : nil } ?? GreenPhrase.all[0]
            default: text = reading.summary ?? "Service issues reported"
            }
            return Line(id: provider, name: provider.displayName, dot: reading.level.dot,
                        text: ProviderStatusClient.oneLine(text))
        }
        if next != lines { lines = next }
    }

    private enum Keys {
        static let enabled = "status.enabled"
        static let lastLevel = "status.lastLevel"
        static let greenPhrase = "status.greenPhrase"
        static let greenDay = "status.greenDay"
    }
}
