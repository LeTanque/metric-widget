import AppKit
import SwiftUI

private struct ThemedRoot<Content: View>: View {
    var themes: ThemeStore
    var sizeBridge: PanelSizeBridge
    var measureContent: Bool
    var content: Content

    var body: some View {
        Group {
            if themes.id == .matrix {
                content
                    .environment(themes)
                    .environment(sizeBridge)
                    .environment(\.colorScheme, .dark)
            } else {
                content
                    .environment(themes)
                    .environment(sizeBridge)
            }
        }
        .reportPanelContentSize(when: measureContent)
    }
}

@MainActor
final class GlassPanelWindow: NSPanel, NSWindowDelegate {
    let panelID: String
    private let themeStore: ThemeStore
    private let layout: PanelLayout
    private let sizeBridge = PanelSizeBridge()
    private var suppressResizeTracking = false
    private var userSized = false

    init<Content: View>(
        id: String,
        layout: PanelLayout,
        themeStore: ThemeStore,
        cornerRadius: CGFloat = 20,
        rootView: Content
    ) {
        self.panelID = id
        self.themeStore = themeStore
        self.layout = layout

        var mask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        if layout.resizable {
            mask.insert(.resizable)
        }

        super.init(
            contentRect: NSRect(origin: .zero, size: layout.defaultSize),
            styleMask: mask,
            backing: .buffered,
            defer: false
        )

        minSize = layout.minSize
        userSized = UserDefaults.standard.bool(forKey: Self.userSizedKey(id))

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isExcludedFromWindowsMenu = true
        isFloatingPanel = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

        sizeBridge.onMeasure = { [weak self] size in
            self?.adoptMeasuredContentSize(size)
        }

        let hosting = NSHostingView(
            rootView: ThemedRoot(
                themes: themeStore,
                sizeBridge: sizeBridge,
                measureContent: layout.sizesToContent,
                content: rootView
            )
        )
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = layout.sizesToContent ? [.intrinsicContentSize] : [.preferredContentSize]
        }

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = cornerRadius
            glass.style = .regular
            glass.contentView = hosting
            contentView = glass
        } else {
            let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: layout.defaultSize))
            effect.material = .hudWindow
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.wantsLayer = true
            effect.layer?.cornerRadius = cornerRadius
            effect.layer?.masksToBounds = true
            hosting.autoresizingMask = [.width, .height]
            effect.addSubview(hosting)
            contentView = effect
        }

        restoreFrame(defaultSize: restoredSize(fallback: layout.defaultSize))
        applyThemeChrome()
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrame()
        guard layout.sizesToContent, !suppressResizeTracking else { return }
        userSized = true
        UserDefaults.standard.set(true, forKey: Self.userSizedKey(panelID))
        persistSize()
    }

    func applyThemeChrome() {
        if #available(macOS 26.0, *) {
            (contentView as? NSGlassEffectView)?.tintColor = themeStore.palette.glassTint
        }
    }

    private func adoptMeasuredContentSize(_ swiftUISize: CGSize) {
        guard layout.sizesToContent else { return }
        let pad: CGFloat = 12
        let targetW = max(layout.minSize.width, swiftUISize.width + pad)
        let targetH = max(layout.minSize.height, swiftUISize.height + pad)

        let needsGrow = targetH > frame.height - 1 || targetW > frame.width - 1
        let needsShrink = !userSized && (targetH < frame.height - 4 || targetW < frame.width - 4)
        guard needsGrow || needsShrink else { return }

        suppressResizeTracking = true
        setContentSize(NSSize(width: targetW, height: targetH))
        suppressResizeTracking = false
    }

    private func restoredSize(fallback: NSSize) -> NSSize {
        let defaults = UserDefaults.standard
        let wKey = Self.widthKey(panelID)
        let hKey = Self.heightKey(panelID)
        if defaults.object(forKey: wKey) != nil, defaults.object(forKey: hKey) != nil {
            let w = max(layout.minSize.width, defaults.double(forKey: wKey))
            let h = max(layout.minSize.height, defaults.double(forKey: hKey))
            return NSSize(width: w, height: h)
        }
        return fallback
    }

    private func restoreFrame(defaultSize: NSSize) {
        setContentSize(defaultSize)
        let defaults = UserDefaults.standard
        let xKey = Self.xKey(panelID)
        let yKey = Self.yKey(panelID)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)

        if defaults.object(forKey: xKey) != nil, defaults.object(forKey: yKey) != nil {
            var origin = NSPoint(x: defaults.double(forKey: xKey), y: defaults.double(forKey: yKey))
            origin.x = min(max(origin.x, screen.minX), screen.maxX - defaultSize.width)
            origin.y = min(max(origin.y, screen.minY), screen.maxY - defaultSize.height)
            setFrameOrigin(origin)
        } else {
            let cascade: CGFloat
            switch panelID {
            case "memory": cascade = 360
            case "system": cascade = 680
            case "combined": cascade = 24
            case "usage": cascade = 1010
            default:
                if panelID.hasPrefix("clock.") {
                    cascade = 180 + CGFloat(abs(panelID.hashValue % 420))
                } else {
                    cascade = 24
                }
            }
            let yOffset: CGFloat = {
                if panelID == "combined" { return 300 }
                if panelID.hasPrefix("clock.") { return 28 + CGFloat(abs(panelID.hashValue % 120)) }
                return 28
            }()
            setFrameOrigin(NSPoint(x: screen.minX + cascade, y: screen.minY + yOffset))
        }
    }

    private func persistFrame() {
        UserDefaults.standard.set(frame.origin.x, forKey: Self.xKey(panelID))
        UserDefaults.standard.set(frame.origin.y, forKey: Self.yKey(panelID))
        persistSize()
    }

    private func persistSize() {
        UserDefaults.standard.set(frame.width, forKey: Self.widthKey(panelID))
        UserDefaults.standard.set(frame.height, forKey: Self.heightKey(panelID))
    }

    private static func xKey(_ id: String) -> String { "panel.\(id).x" }
    private static func yKey(_ id: String) -> String { "panel.\(id).y" }
    private static func widthKey(_ id: String) -> String { "panel.\(id).width" }
    private static func heightKey(_ id: String) -> String { "panel.\(id).height" }
    private static func userSizedKey(_ id: String) -> String { "panel.\(id).userSized" }
}
