import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ThemeID: String, CaseIterable, Identifiable {
    case system
    case matrix
    case graffiti
    case dark
    case darker
    case light
    case custom

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .system: "System"
        case .matrix: "Matrix"
        case .graffiti: "Graffiti"
        case .dark: "Dark"
        case .darker: "Darker"
        case .light: "Light"
        case .custom: "Custom"
        }
    }

    var usesMuralBackground: Bool {
        self == .graffiti || self == .custom
    }
}

/// Custom theme color mode, named for the BACKGROUND it suits:
/// `.dark` = white ink for dark pictures, `.light` = dark ink for light pictures.
enum CustomColorTheme: String, CaseIterable, Identifiable {
    case dark
    case darker
    case light

    var id: String { rawValue }
    var menuTitle: String {
        switch self {
        case .dark: "Dark"
        case .darker: "Darker"
        case .light: "Light"
        }
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
    /// Tile title band (GROK BOT, STATUS, …): fill, title text, secondary text.
    var headerFill: Color = ArcadeTileChrome.plotFill
    var headerTitle: Color = ArcadeTileChrome.value
    var headerLabel: Color = ArcadeTileChrome.label

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
        baseline: Color(red: 95.0 / 255.0, green: 211.0 / 255.0, blue: 176.0 / 255.0).opacity(0.5),
        headerTitle: Color(red: 242.0 / 255.0, green: 244.0 / 255.0, blue: 243.0 / 255.0),
        headerLabel: Color(red: 184.0 / 255.0, green: 208.0 / 255.0, blue: 200.0 / 255.0)
    )

    /// Dark ink for light backgrounds; title bands stay black with white text.
    static let darkInk = ArcadeChrome(
        upload: Color(red: 0.55, green: 0.22, blue: 0.0),
        download: Color(red: 0.0, green: 0.36, blue: 0.40),
        accent: Color(red: 0.0, green: 0.36, blue: 0.40),
        warning: Color(red: 0.72, green: 0.04, blue: 0.12),
        label: Color(white: 0.24),
        value: Color(white: 0.04),
        plotFill: Color.white.opacity(0.55),
        grid: Color.black.opacity(0.14),
        baseline: Color.black.opacity(0.32),
        headerFill: Color(white: 0.04),
        headerTitle: Color.white,
        headerLabel: Color(white: 0.72)
    )

    /// Darker: Dark's white ink, but red bars/network and dark-gray title bands.
    /// Bar red = the Dark gauge-ring red (lightInk.warning); alert is a deeper red.
    static let darkerInk: ArcadeChrome = {
        var c = ArcadeChrome.lightInk
        c.accent = Color(red: 1.0, green: 0.36, blue: 0.36)
        c.download = Color(red: 1.0, green: 0.36, blue: 0.36)
        c.upload = Color(red: 1.0, green: 0.66, blue: 0.60)
        c.warning = Color(red: 0.58, green: 0.03, blue: 0.07)
        c.headerFill = Color(white: 0.22)
        c.headerTitle = Color.white
        c.headerLabel = Color(white: 0.72)
        return c
    }()

    /// Light ink for dark backgrounds; title bands inverted to white with black text.
    static let lightInk = ArcadeChrome(
        upload: Color.white,
        download: Color(red: 0.55, green: 0.90, blue: 1.0),
        accent: Color(red: 0.55, green: 0.90, blue: 1.0),
        warning: Color(red: 1.0, green: 0.36, blue: 0.36),
        label: Color(white: 0.78),
        value: Color.white,
        plotFill: Color.black.opacity(0.55),
        grid: Color.white.opacity(0.16),
        baseline: Color.white.opacity(0.4),
        headerFill: Color.white,
        headerTitle: Color.black,
        headerLabel: Color(white: 0.25)
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
        segmentOn: Color(red: 250.0 / 255.0, green: 154.0 / 255.0, blue: 112.0 / 255.0),
        segmentOff: Color(red: 196.0 / 255.0, green: 122.0 / 255.0, blue: 98.0 / 255.0).opacity(0.14),
        segmentGlow: false,
        clockLED: Color(red: 250.0 / 255.0, green: 154.0 / 255.0, blue: 112.0 / 255.0),
        clockLEDOffColor: Color(red: 196.0 / 255.0, green: 122.0 / 255.0, blue: 98.0 / 255.0).opacity(0.14),
        glassTint: NSColor(calibratedWhite: 0, alpha: 0.55),
        arcade: .graffiti,
        clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.55),
        glassMaterial: .underWindowBackground
    )
}

extension ThemePalette {
    /// Unlit LED segments for the Dark/Light inks: faint enough that digits don't read as 8s.
    static let inkLEDOffOpacity: Double = 0.025
    /// Dark-ink (Light) palette unlit segments: a touch more visible.
    static let darkInkLEDOffOpacity: Double = 0.07

    /// Dark ink (for light pictures / the Dark theme): very dark orange LEDs, black text.
    static func darkInk(glassTint: NSColor?, clockGlassTint: NSColor) -> ThemePalette {
        let led = Color(red: 0.72, green: 0.20, blue: 0.0)
        return ThemePalette(
            titleFont: .caption.weight(.semibold),
            captionFont: .caption,
            caption2Font: .caption2,
            bodyFont: .callout.monospacedDigit().weight(.medium),
            valueFont: .caption.monospacedDigit(),
            primary: Color(white: 0.06),
            secondary: Color(white: 0.06).opacity(0.78),
            tertiary: Color(white: 0.06).opacity(0.5),
            accent: ArcadeChrome.darkInk.accent,
            track: Color.black.opacity(0.18),
            down: ArcadeChrome.darkInk.download,
            up: ArcadeChrome.darkInk.upload,
            warning: ArcadeChrome.darkInk.warning,
            barLabel: Color(white: 0.04),
            segmentOn: led,
            segmentOff: led.opacity(darkInkLEDOffOpacity),
            segmentGlow: false,
            clockLED: led,
            clockLEDOffColor: led.opacity(darkInkLEDOffOpacity),
            glassTint: glassTint,
            arcade: .darkInk,
            clockGlassTint: clockGlassTint,
            glassMaterial: .underWindowBackground
        )
    }

    /// Light ink (for dark pictures / the Light theme): white glowing LEDs, white text.
    static func lightInk(glassTint: NSColor?, clockGlassTint: NSColor, arcade: ArcadeChrome = .lightInk) -> ThemePalette {
        let led = Color.white
        return ThemePalette(
            titleFont: .caption.weight(.semibold),
            captionFont: .caption,
            caption2Font: .caption2,
            bodyFont: .callout.monospacedDigit().weight(.medium),
            valueFont: .caption.monospacedDigit(),
            primary: Color.white,
            secondary: Color.white.opacity(0.8),
            tertiary: Color.white.opacity(0.5),
            accent: arcade.accent,
            track: Color.black.opacity(0.45),
            down: arcade.download,
            up: arcade.upload,
            warning: arcade.warning,
            barLabel: Color.white,
            segmentOn: led,
            segmentOff: led.opacity(inkLEDOffOpacity),
            segmentGlow: true,
            clockLED: led,
            clockLEDOffColor: led.opacity(inkLEDOffOpacity),
            glassTint: glassTint,
            arcade: arcade,
            clockGlassTint: clockGlassTint,
            glassMaterial: .underWindowBackground
        )
    }

    static let customDarkInk = darkInk(glassTint: NSColor(calibratedWhite: 1, alpha: 0.35), clockGlassTint: NSColor(calibratedWhite: 1, alpha: 0.35))
    static let customLightInk = lightInk(glassTint: NSColor(calibratedWhite: 0, alpha: 0.55), clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.55))
    static let customDarkerInk = lightInk(glassTint: NSColor(calibratedWhite: 0, alpha: 0.55), clockGlassTint: NSColor(calibratedWhite: 0, alpha: 0.55), arcade: .darkerInk)
    /// Standalone Light theme: dark ink on a plain light-gray panel.
    static let lightPanelTheme = darkInk(glassTint: NSColor(calibratedWhite: 0.93, alpha: 0.9), clockGlassTint: NSColor(calibratedWhite: 0.93, alpha: 0.85))
    /// Standalone Dark theme: light ink on a plain near-black panel.
    static let darkPanelTheme = lightInk(glassTint: NSColor(calibratedWhite: 0.06, alpha: 0.88), clockGlassTint: NSColor(calibratedWhite: 0.06, alpha: 0.8))
    /// Standalone Darker theme: Dark's panel and ink with red bars and gray title bands.
    static let darkerPanelTheme = lightInk(glassTint: NSColor(calibratedWhite: 0.06, alpha: 0.88), clockGlassTint: NSColor(calibratedWhite: 0.06, alpha: 0.8), arcade: .darkerInk)
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

    var customColorTheme: CustomColorTheme {
        didSet { UserDefaults.standard.set(customColorTheme.rawValue, forKey: Keys.customInk) }
    }

    /// True when the active palette uses dark ink (needs a light color scheme and a light scrim).
    var usesDarkInk: Bool {
        id == .light || (id == .custom && customColorTheme == .light)
    }

    var customBackgroundPath: String?
    var customBackgroundName: String?

    var palette: ThemePalette {
        switch id {
        case .system: .system
        case .matrix: .matrix
        case .graffiti: .graffiti
        case .dark: .darkPanelTheme
        case .darker: .darkerPanelTheme
        case .light: .lightPanelTheme
        case .custom:
            switch customColorTheme {
            case .dark: .customLightInk
            case .darker: .customDarkerInk
            case .light: .customDarkInk
            }
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
        Self.migrateBackgroundNaming()
        let raw = UserDefaults.standard.string(forKey: "app.theme") ?? ""
        id = ThemeID(rawValue: raw) ?? .system
        customColorTheme = CustomColorTheme(rawValue: UserDefaults.standard.string(forKey: Keys.customInk) ?? "") ?? .dark
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

    /// One-time swap: Dark/Light used to name the ink, now they name the background.
    /// Old "dark" (dark ink) becomes "light" and vice versa, so every saved look is unchanged.
    static func migrateBackgroundNaming(_ defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: Keys.namingMigrated) else { return }
        for key in ["app.theme", Keys.customInk] {
            switch defaults.string(forKey: key) {
            case "dark": defaults.set("light", forKey: key)
            case "light": defaults.set("dark", forKey: key)
            default: break
            }
        }
        defaults.set(true, forKey: Keys.namingMigrated)
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
        static let customInk = "theme.customColorTheme"
        static let namingMigrated = "theme.backgroundNamingMigrated"
    }
}
