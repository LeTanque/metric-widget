import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ThemeID: String, CaseIterable, Identifiable {
    case system
    case matrix
    case graffiti
    case custom

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .system: "System"
        case .matrix: "Matrix"
        case .graffiti: "Graffiti"
        case .custom: "Custom"
        }
    }

    var usesMuralBackground: Bool {
        self == .graffiti || self == .custom
    }
}

struct ArcadeChrome: Equatable, Sendable {
    var upload: Color
    var download: Color
    var accent: Color
    var warning: Color
    var label: Color
    var value: Color
    var plotFill: Color
    var grid: Color
    var baseline: Color

    static var standard: ArcadeChrome {
        ArcadeChrome(
            upload: ArcadeTileChrome.upload,
            download: ArcadeTileChrome.download,
            accent: ArcadeTileChrome.accent,
            warning: ArcadeTileChrome.warning,
            label: ArcadeTileChrome.label,
            value: ArcadeTileChrome.value,
            plotFill: ArcadeTileChrome.plotFill,
            grid: ArcadeTileChrome.grid,
            baseline: ArcadeTileChrome.baseline
        )
    }

    static let graffiti = ArcadeChrome(
        upload: Color(red: 196.0 / 255.0, green: 138.0 / 255.0, blue: 232.0 / 255.0),
        download: Color(red: 95.0 / 255.0, green: 211.0 / 255.0, blue: 176.0 / 255.0),
        accent: Color(red: 46.0 / 255.0, green: 143.0 / 255.0, blue: 168.0 / 255.0),
        warning: Color(red: 229.0 / 255.0, green: 106.0 / 255.0, blue: 90.0 / 255.0),
        label: Color(red: 184.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0),
        value: Color(red: 242.0 / 255.0, green: 244.0 / 255.0, blue: 243.0 / 255.0),
        plotFill: Color.black,
        grid: Color(red: 46.0 / 255.0, green: 143.0 / 255.0, blue: 168.0 / 255.0),
        baseline: Color(red: 95.0 / 255.0, green: 211.0 / 255.0, blue: 176.0 / 255.0).opacity(0.5)
    )
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
    var clockLED: Color
    var clockLEDOffColor: Color? = nil
    var clockLEDOff: Color { clockLEDOffColor ?? clockLED.opacity(ClockLEDChrome.offOpacity) }
    var glassTint: NSColor?
    var arcade: ArcadeChrome = .standard
    /// Extra-dark smoked glass for clock panels (black at lower opacity).
    var clockGlassTint: NSColor
    var glassMaterial: NSVisualEffectView.Material

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
        clockLED: Color(red: 1.0, green: 0.45, blue: 0.05),
        glassTint: NSColor(calibratedWhite: 0, alpha: 0.62),
        clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.28),
        glassMaterial: .underWindowBackground
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
        clockLED: Color(red: 0.35, green: 1.0, blue: 0.28),
        glassTint: NSColor(calibratedWhite: 0, alpha: 0.82),
        clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.32),
        glassMaterial: .underWindowBackground
    )

    static let graffiti = ThemePalette(
        titleFont: .caption.weight(.semibold),
        captionFont: .caption,
        caption2Font: .caption2,
        bodyFont: .callout.monospacedDigit().weight(.medium),
        valueFont: .caption.monospacedDigit(),
        primary: Color(red: 184.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0),
        secondary: Color(red: 184.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0).opacity(0.78),
        tertiary: Color(red: 184.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0).opacity(0.5),
        accent: Color(red: 46.0 / 255.0, green: 143.0 / 255.0, blue: 168.0 / 255.0),
        track: Color.black.opacity(0.45),
        down: Color(red: 95.0 / 255.0, green: 211.0 / 255.0, blue: 176.0 / 255.0),
        up: Color(red: 196.0 / 255.0, green: 138.0 / 255.0, blue: 232.0 / 255.0),
        warning: Color(red: 229.0 / 255.0, green: 106.0 / 255.0, blue: 90.0 / 255.0),
        barLabel: Color(red: 242.0 / 255.0, green: 244.0 / 255.0, blue: 243.0 / 255.0),
        segmentOn: Color(red: 246.0 / 255.0, green: 168.0 / 255.0, blue: 137.0 / 255.0),
        segmentOff: Color(red: 196.0 / 255.0, green: 122.0 / 255.0, blue: 98.0 / 255.0),
        segmentGlow: false,
        clockLED: Color(red: 246.0 / 255.0, green: 168.0 / 255.0, blue: 137.0 / 255.0),
        clockLEDOffColor: Color(red: 196.0 / 255.0, green: 122.0 / 255.0, blue: 98.0 / 255.0),
        glassTint: NSColor(calibratedWhite: 0, alpha: 0.55),
        arcade: .graffiti,
        clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.55),
        glassMaterial: .underWindowBackground
    )
}

enum ClockLEDChrome {
    static let offOpacity: Double = 0.07

    static func off(_ on: Color) -> Color {
        on.opacity(offOpacity)
    }
}

@MainActor
@Observable
final class ThemeStore {
    var id: ThemeID {
        didSet { UserDefaults.standard.set(id.rawValue, forKey: "app.theme") }
    }

    var customBackgroundPath: String?
    var customBackgroundName: String?

    var palette: ThemePalette {
        switch id {
        case .system: .system
        case .matrix: .matrix
        case .graffiti, .custom: .graffiti
        }
    }

    var customBackgroundFileName: String? {
        guard hasCustomBackground else { return nil }
        if let customBackgroundName, !customBackgroundName.isEmpty {
            return customBackgroundName
        }
        if let customBackgroundPath {
            return URL(fileURLWithPath: customBackgroundPath).lastPathComponent
        }
        return nil
    }

    var hasCustomBackground: Bool {
        guard let customBackgroundPath else { return false }
        return FileManager.default.fileExists(atPath: customBackgroundPath)
    }

    private var muralCache: NSImage?
    private var muralCacheKey: String?

    init() {
        IdentityMigration.runIfNeeded()
        let raw = UserDefaults.standard.string(forKey: "app.theme") ?? ""
        id = ThemeID(rawValue: raw) ?? .system
        customBackgroundPath = UserDefaults.standard.string(forKey: Keys.customPath)
        customBackgroundName = UserDefaults.standard.string(forKey: Keys.customName)
    }

    func muralImage() -> NSImage? {
        if id == .custom, let path = customBackgroundPath, FileManager.default.fileExists(atPath: path) {
            let key = "custom:" + path
            if muralCacheKey == key, let muralCache {
                return muralCache
            }
            if let image = NSImage(contentsOfFile: path) {
                muralCache = image
                muralCacheKey = key
                return image
            }
        }
        let key = "graffiti"
        if muralCacheKey == key, let muralCache {
            return muralCache
        }
        if let image = MuralResource.image() {
            muralCache = image
            muralCacheKey = key
            return image
        }
        return nil
    }

    func installCustomBackgroundFromOpenPanel() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.jpeg, .png, .heic]
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url else {
            return false
        }
        return installCustomBackground(from: url)
    }

    func removeCustomBackground() {
        if let folder = Self.supportDirectory(),
           let items = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
            for item in items where item.lastPathComponent.hasPrefix("custom-background.") {
                try? FileManager.default.removeItem(at: item)
            }
        }
        customBackgroundPath = nil
        customBackgroundName = nil
        muralCache = nil
        muralCacheKey = nil
        UserDefaults.standard.removeObject(forKey: Keys.customPath)
        UserDefaults.standard.removeObject(forKey: Keys.customName)
    }

    private func installCustomBackground(from url: URL) -> Bool {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard let folder = Self.supportDirectory() else { return false }
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            if let items = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                for item in items where item.lastPathComponent.hasPrefix("custom-background.") {
                    try? fileManager.removeItem(at: item)
                }
            }
            let ext = Self.normalizedExtension(url.pathExtension)
            let dest = folder.appendingPathComponent("custom-background.\(ext)")
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            try fileManager.copyItem(at: url, to: dest)
            customBackgroundPath = dest.path
            customBackgroundName = url.lastPathComponent
            muralCache = nil
            muralCacheKey = nil
            UserDefaults.standard.set(dest.path, forKey: Keys.customPath)
            UserDefaults.standard.set(url.lastPathComponent, forKey: Keys.customName)
            return true
        } catch {
            return false
        }
    }

    private static func supportDirectory() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MetricsWidget", isDirectory: true)
    }

    private static func normalizedExtension(_ raw: String) -> String {
        let ext = raw.lowercased()
        switch ext {
        case "jpeg":
            return "jpg"
        case "jpg", "png", "heic":
            return ext
        default:
            return "jpg"
        }
    }

    private enum Keys {
        static let customPath = "theme.customBackgroundPath"
        static let customName = "theme.customBackgroundName"
    }
}
