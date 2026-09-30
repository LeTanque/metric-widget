import Foundation
import Observation

@MainActor
@Observable
final class ClockPreferences {
    private(set) var enabledZones: Set<ClockTimeZoneChoice> = [.device]

    func reload() {
        let defaults = UserDefaults.standard
        guard let raw = defaults.stringArray(forKey: Keys.enabledZones) else {
            enabledZones = [.device]
            return
        }
        let parsed = Set(raw.compactMap { ClockTimeZoneChoice(rawValue: $0) })
        enabledZones = parsed.isEmpty ? [.device] : parsed
    }

    func isEnabled(_ zone: ClockTimeZoneChoice) -> Bool {
        enabledZones.contains(zone)
    }

    func setEnabled(_ zone: ClockTimeZoneChoice, _ on: Bool) {
        if on {
            enabledZones.insert(zone)
        } else {
            enabledZones.remove(zone)
        }
        persist()
    }

    func persist() {
        let raw = enabledZones.map(\.rawValue).sorted()
        UserDefaults.standard.set(raw, forKey: Keys.enabledZones)
    }

    private enum Keys {
        static let enabledZones = "clock.enabledZones"
    }
}
