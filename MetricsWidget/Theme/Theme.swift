import AppKit
import SwiftUI

enum ThemeID: String, CaseIterable, Identifiable {
    case system
    case matrix

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .system: "System"
        case .matrix: "Matrix"
        }
    }
}

struct ThemePalette {
    var titleFont: Font
    var captionFont: Font
    var caption2Font: Font
    var bodyFont: Font
    var valueFont: Font
    var primary: Color
    var secondary: Color
    var tertiary: Color
    var accent: Color
    var track: Color
    var down: Color
    var up: Color
    var warning: Color
    var barLabel: Color
    var segmentOn: Color
    var segmentOff: Color
    var segmentGlow: Bool
    var glassTint: NSColor?

    static let system = ThemePalette(
        titleFont: .caption.weight(.semibold),
        captionFont: .caption,
        caption2Font: .caption2,
        bodyFont: .callout.monospacedDigit().weight(.medium),
        valueFont: .caption.monospacedDigit(),
        primary: .primary,
        secondary: .secondary,
        tertiary: Color.secondary.opacity(0.55),
        accent: .accentColor,
        track: Color.secondary.opacity(0.28),
        down: .blue,
        up: .green,
        warning: .orange,
        barLabel: .primary,
        segmentOn: Color.accentColor,
        segmentOff: Color.secondary.opacity(0.22),
        segmentGlow: false,
        glassTint: nil
    )

    static let matrix = ThemePalette(
        titleFont: .custom("Menlo", size: 11).weight(.bold),
        captionFont: .custom("Menlo", size: 11),
        caption2Font: .custom("Menlo", size: 10),
        bodyFont: .custom("Menlo", size: 13).weight(.medium),
        valueFont: .custom("Menlo", size: 11),
        primary: Color(red: 0.55, green: 1.0, blue: 0.45),
        secondary: Color(red: 0.28, green: 0.78, blue: 0.32),
        tertiary: Color(red: 0.16, green: 0.48, blue: 0.22),
        accent: Color(red: 0.35, green: 1.0, blue: 0.28),
        track: Color(red: 0.08, green: 0.28, blue: 0.12).opacity(0.9),
        down: Color(red: 0.20, green: 0.85, blue: 0.40),
        up: Color(red: 0.70, green: 1.0, blue: 0.45),
        warning: Color(red: 0.85, green: 1.0, blue: 0.30),
        barLabel: Color(red: 0.55, green: 1.0, blue: 0.88),
        segmentOn: Color(red: 0.0, green: 0.98, blue: 0.82),
        segmentOff: Color(red: 0.02, green: 0.06, blue: 0.05),
        segmentGlow: true,
        glassTint: NSColor(calibratedRed: 0.05, green: 0.55, blue: 0.12, alpha: 0.55)
    )
}

@MainActor
@Observable
final class ThemeStore {
    var id: ThemeID {
        didSet { UserDefaults.standard.set(id.rawValue, forKey: "app.theme") }
    }

    var palette: ThemePalette {
        switch id {
        case .system: .system
        case .matrix: .matrix
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "app.theme") ?? ""
        id = ThemeID(rawValue: raw) ?? .system
    }
}
