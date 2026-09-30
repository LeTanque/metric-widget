import Foundation

enum ClockTimeZoneChoice: String, CaseIterable, Identifiable, Codable {
    case device
    case utc
    case americaLosAngeles
    case nice
    case americaDenver
    case americaChicago
    case americaNewYork
    case europeLondon
    case europeParis
    case asiaTokyo
    case asiaSingapore
    case australiaSydney

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .device: "Local"
        case .utc: "UTC"
        case .americaLosAngeles: "Los Angeles"
        case .nice: "Nice"
        case .americaDenver: "Denver"
        case .americaChicago: "Chicago"
        case .americaNewYork: "New York"
        case .europeLondon: "London"
        case .europeParis: "Paris"
        case .asiaTokyo: "Tokyo"
        case .asiaSingapore: "Singapore"
        case .australiaSydney: "Sydney"
        }
    }

    var timeZone: TimeZone {
        switch self {
        case .device:
            .current
        case .utc:
            TimeZone(secondsFromGMT: 0) ?? .gmt
        case .americaLosAngeles, .nice:
            TimeZone(identifier: "America/Los_Angeles") ?? .current
        case .americaDenver:
            TimeZone(identifier: "America/Denver") ?? .current
        case .americaChicago:
            TimeZone(identifier: "America/Chicago") ?? .current
        case .americaNewYork:
            TimeZone(identifier: "America/New_York") ?? .current
        case .europeLondon:
            TimeZone(identifier: "Europe/London") ?? .current
        case .europeParis:
            TimeZone(identifier: "Europe/Paris") ?? .current
        case .asiaTokyo:
            TimeZone(identifier: "Asia/Tokyo") ?? .current
        case .asiaSingapore:
            TimeZone(identifier: "Asia/Singapore") ?? .current
        case .australiaSydney:
            TimeZone(identifier: "Australia/Sydney") ?? .current
        }
    }

    var label: String {
        switch self {
        case .device:
            if let city = TimeZone.current.identifier.split(separator: "/").last {
                return String(city).replacingOccurrences(of: "_", with: " ")
            }
            return "Local"
        case .nice:
            return "Nice"
        default:
            return menuTitle
        }
    }

    var panelID: String { "clock.\(rawValue)" }
}
