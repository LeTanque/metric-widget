import AppKit
import CoreText
import SwiftUI

enum NetworkArcadeFont {
    static let familyName = "Press Start 2P"
    static let fallbackFamily = "Menlo"
    private static var didRegister = false

    static func register() {
        guard !didRegister else { return }
        didRegister = true
        for url in fontURLs() {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static func font(size: CGFloat) -> Font {
        register()
        if NSFont(name: familyName, size: size) != nil {
            return .custom(familyName, size: size)
        }
        if NSFont(name: "PressStart2P-Regular", size: size) != nil {
            return .custom("PressStart2P-Regular", size: size)
        }
        return .custom(fallbackFamily, size: size).weight(.bold)
    }

    private static func fontURLs() -> [URL] {
        var found: [URL] = []
        var seen = Set<String>()

        func append(_ url: URL?) {
            guard let url else { return }
            let path = url.path
            guard FileManager.default.fileExists(atPath: path), !seen.contains(path) else { return }
            seen.insert(path)
            found.append(url)
        }

        #if SWIFT_PACKAGE
        append(Bundle.module.url(forResource: "PressStart2P-Regular", withExtension: "ttf"))
        append(Bundle.module.url(forResource: "PressStart2P-Regular", withExtension: "ttf", subdirectory: "Fonts"))
        #endif

        append(Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf"))
        append(Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf", subdirectory: "Fonts"))
        append(Bundle.main.url(forResource: "PressStart2P-Regular", withExtension: "ttf", subdirectory: "Resources/Fonts"))

        if let resources = Bundle.main.resourceURL {
            append(resources.appendingPathComponent("PressStart2P-Regular.ttf"))
            append(resources.appendingPathComponent("Fonts/PressStart2P-Regular.ttf"))
        }

        let bundleNames = ["MetricsWidget_MetricsWidget.bundle", "MetricsWidget.bundle"]
        var searchRoots: [URL] = []
        if let execDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            searchRoots.append(execDir)
            searchRoots.append(execDir.deletingLastPathComponent().appendingPathComponent("Resources"))
        }
        if let resourceURL = Bundle.main.resourceURL {
            searchRoots.append(resourceURL)
        }

        for root in searchRoots {
            append(root.appendingPathComponent("PressStart2P-Regular.ttf"))
            append(root.appendingPathComponent("Fonts/PressStart2P-Regular.ttf"))
            for name in bundleNames {
                if let bundle = Bundle(url: root.appendingPathComponent(name)) {
                    append(bundle.url(forResource: "PressStart2P-Regular", withExtension: "ttf"))
                    append(bundle.url(forResource: "PressStart2P-Regular", withExtension: "ttf", subdirectory: "Fonts"))
                }
            }
        }

        return found
    }
}
