import AppKit
import SwiftUI

enum PanelWindowShape: Equatable {
    case rounded(CGFloat)
    case chamferedBottomRight(CGFloat)
}

private struct ThemedRoot<Content: View>: View {
    var themes: ThemeStore
    var sizeBridge: PanelSizeBridge
    var measureContent: Bool
    var measureMode: PanelContentMeasureMode
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
        .reportPanelContentSize(when: measureContent, bridge: sizeBridge, mode: measureMode)
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
    private var usesClockGlassTint = false
    private let windowShape: PanelWindowShape
    private var shapeBorderLayer: CAShapeLayer?
    private var tintOverlay: NSView?
    private var isApplyingSnap = false

    init<Content: View>(
        id: String,
        layout: PanelLayout,
        themeStore: ThemeStore,
        shape: PanelWindowShape = .rounded(20),
        clockGlass: Bool = true,
        rootView: Content
    ) {
        self.panelID = id
        self.themeStore = themeStore
        self.layout = layout
        self.windowShape = shape
        self.usesClockGlassTint = clockGlass

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
        contentMinSize = layout.minSize
        applySizeLimits(Self.maxPanelSize(for: layout))
        userSized = UserDefaults.standard.bool(forKey: Self.userSizedKey(id))

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
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
                measureMode: layout.contentMeasureMode,
                content: rootView
            )
        )
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = [.preferredContentSize]
        }
        hosting.frame = NSRect(origin: .zero, size: layout.defaultSize)
        hosting.autoresizingMask = [.width, .height]

        let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: layout.defaultSize))
        effect.material = themeStore.palette.glassMaterial
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = Self.roundedRadius(for: shape)
        effect.layer?.masksToBounds = true
        effect.layer?.borderWidth = 0
        effect.layer?.borderColor = nil
        let overlay = NSView(frame: effect.bounds)
        overlay.wantsLayer = true
        overlay.autoresizingMask = [.width, .height]
        overlay.layer?.backgroundColor = Self.panelTint(
            clockGlass: clockGlass,
            palette: themeStore.palette
        ).cgColor
        effect.addSubview(overlay)
        effect.addSubview(hosting)
        tintOverlay = overlay
        contentView = effect

        restoreFrame(defaultSize: restoredSize(fallback: layout.defaultSize))
        applyThemeChrome()
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func windowDidMove(_ notification: Notification) {
        if !isApplyingSnap, NSEvent.pressedMouseButtons != 0 {
            let snapped = PanelSnapper.origin(for: self)
            if abs(snapped.x - frame.origin.x) > 0.5 || abs(snapped.y - frame.origin.y) > 0.5 {
                isApplyingSnap = true
                setFrameOrigin(snapped)
                isApplyingSnap = false
            }
        }
        persistFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrame()
        applyWindowShape()
        guard layout.sizesToContent, !suppressResizeTracking else { return }
        userSized = true
        UserDefaults.standard.set(true, forKey: Self.userSizedKey(panelID))
        persistSize()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        applySizeLimits(Self.maxPanelSize(for: layout, screen: screen))
    }

    func applyThemeChrome() {
        let palette = themeStore.palette
        if let effect = contentView as? NSVisualEffectView {
            effect.material = usesClockGlassTint ? .hudWindow : palette.glassMaterial
        }
        tintOverlay?.layer?.backgroundColor = Self.panelTint(
            clockGlass: usesClockGlassTint,
            palette: palette
        ).cgColor
        applyWindowShape()
    }

    private func applyWindowShape() {
        guard let view = contentView else { return }
        view.wantsLayer = true
        switch windowShape {
        case .rounded(let radius):
            view.layer?.mask = nil
            view.layer?.cornerRadius = radius
            view.layer?.masksToBounds = true
            view.layer?.borderWidth = 0
            view.layer?.borderColor = nil
            shapeBorderLayer?.removeFromSuperlayer()
            shapeBorderLayer = nil
        case .chamferedBottomRight(let chamfer):
            view.layer?.cornerRadius = 0
            view.layer?.masksToBounds = true
            guard view.bounds.width > 1, view.bounds.height > 1 else { return }
            let mask = (view.layer?.mask as? CAShapeLayer) ?? CAShapeLayer()
            mask.path = ChamferedRect.appKitPath(in: view.bounds, chamfer: chamfer)
            view.layer?.mask = mask
            view.layer?.borderWidth = 0
            view.layer?.borderColor = nil
            shapeBorderLayer?.removeFromSuperlayer()
            shapeBorderLayer = nil
        }
    }

    private static func panelTint(clockGlass: Bool, palette: ThemePalette) -> NSColor {
        if clockGlass {
            return palette.clockGlassTint
        }
        return palette.glassTint ?? .clear
    }

    private static func roundedRadius(for shape: PanelWindowShape) -> CGFloat {
        switch shape {
        case .rounded(let radius):
            return radius
        case .chamferedBottomRight:
            return 0
        }
    }

    private func adoptMeasuredContentSize(_ swiftUISize: CGSize) {
        guard layout.sizesToContent else { return }
        guard swiftUISize.width.isFinite, swiftUISize.height.isFinite else { return }
        guard swiftUISize.width > 0, swiftUISize.height > 0 else { return }

        let pad: CGFloat = 12
        let limit = Self.maxPanelSize(for: layout, screen: screen)
        let current = contentRect(forFrameRect: frame).size
        let targetW = Self.axisSize(
            measured: swiftUISize.width,
            current: current.width,
            minLength: layout.minSize.width,
            maxLength: limit.width,
            pad: pad,
            allowShrink: !userSized
        )
        let targetH = Self.axisSize(
            measured: swiftUISize.height,
            current: current.height,
            minLength: layout.minSize.height,
            maxLength: limit.height,
            pad: pad,
            allowShrink: !userSized
        )

        guard abs(targetW - current.width) > 0.5 || abs(targetH - current.height) > 0.5 else { return }

        suppressResizeTracking = true
        setContentSize(NSSize(width: targetW, height: targetH))
        applyWindowShape()
        suppressResizeTracking = false
    }

    private func restoredSize(fallback: NSSize) -> NSSize {
        let defaults = UserDefaults.standard
        let generationKey = Self.generationKey(panelID)
        let storedGeneration = defaults.integer(forKey: generationKey)
        if layout.frameGeneration > 1, storedGeneration < layout.frameGeneration {
            defaults.removeObject(forKey: Self.widthKey(panelID))
            defaults.removeObject(forKey: Self.heightKey(panelID))
            defaults.set(false, forKey: Self.userSizedKey(panelID))
            defaults.set(layout.frameGeneration, forKey: generationKey)
            userSized = false
            return fallback
        }
        if storedGeneration != layout.frameGeneration {
            defaults.set(layout.frameGeneration, forKey: generationKey)
        }
        let wKey = Self.widthKey(panelID)
        let hKey = Self.heightKey(panelID)
        if panelID == "network" {
            let migrateKey = Self.networkWidth320Key
            if defaults.object(forKey: migrateKey) == nil {
                defaults.set(true, forKey: migrateKey)
                if defaults.object(forKey: wKey) != nil {
                    defaults.set(layout.defaultSize.width, forKey: wKey)
                }
            }
        }
        guard defaults.object(forKey: wKey) != nil, defaults.object(forKey: hKey) != nil else {
            return fallback
        }
        let stored = NSSize(width: defaults.double(forKey: wKey), height: defaults.double(forKey: hKey))
        let limit = Self.maxPanelSize(for: layout, screen: screen)
        guard Self.isPlausibleStoredSize(stored, maxSize: limit) else {
            defaults.removeObject(forKey: wKey)
            defaults.removeObject(forKey: hKey)
            defaults.set(false, forKey: Self.userSizedKey(panelID))
            userSized = false
            return fallback
        }
        return Self.clampSize(stored, minSize: layout.minSize, maxSize: limit)
    }

    private func restoreFrame(defaultSize: NSSize) {
        let size = Self.clampSize(
            defaultSize,
            minSize: layout.minSize,
            maxSize: Self.maxPanelSize(for: layout, screen: screen)
        )
        applySizeLimits(Self.maxPanelSize(for: layout, screen: screen))
        setContentSize(size)
        let defaults = UserDefaults.standard
        let xKey = Self.xKey(panelID)
        let yKey = Self.yKey(panelID)
        let screen = visibleScreenFrame()

        if defaults.object(forKey: xKey) != nil, defaults.object(forKey: yKey) != nil {
            var origin = NSPoint(x: defaults.double(forKey: xKey), y: defaults.double(forKey: yKey))
            origin.x = min(max(origin.x, screen.minX), max(screen.minX, screen.maxX - size.width))
            origin.y = min(max(origin.y, screen.minY), max(screen.minY, screen.maxY - size.height))
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
        let screen = visibleScreenFrame()
        let size = clampedFrameSize()
        var origin = frame.origin
        origin.x = min(max(origin.x, screen.minX), max(screen.minX, screen.maxX - size.width))
        origin.y = min(max(origin.y, screen.minY), max(screen.minY, screen.maxY - size.height))
        UserDefaults.standard.set(origin.x, forKey: Self.xKey(panelID))
        UserDefaults.standard.set(origin.y, forKey: Self.yKey(panelID))
        persistSize()
    }

    private func persistSize() {
        let size = clampedFrameSize()
        UserDefaults.standard.set(size.width, forKey: Self.widthKey(panelID))
        UserDefaults.standard.set(size.height, forKey: Self.heightKey(panelID))
    }

    private func clampedFrameSize() -> NSSize {
        Self.clampSize(
            frame.size,
            minSize: layout.minSize,
            maxSize: Self.maxPanelSize(for: layout, screen: screen)
        )
    }

    private func applySizeLimits(_ limit: NSSize) {
        maxSize = limit
        contentMaxSize = limit
    }

    private func visibleScreenFrame() -> NSRect {
        (screen ?? NSScreen.main)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
    }

    private static func maxPanelSize(for layout: PanelLayout, screen: NSScreen? = nil) -> NSSize {
        let visible = (screen ?? NSScreen.main)?.visibleFrame.size ?? NSSize(width: 1280, height: 800)
        return NSSize(
            width: max(layout.minSize.width, min(visible.width, layout.maxSize.width)),
            height: max(layout.minSize.height, min(visible.height, layout.maxSize.height))
        )
    }

    private static func clampSize(_ size: NSSize, minSize: NSSize, maxSize: NSSize) -> NSSize {
        NSSize(
            width: clamp(size.width, min: minSize.width, max: maxSize.width),
            height: clamp(size.height, min: minSize.height, max: maxSize.height)
        )
    }

    private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        guard value.isFinite else { return min }
        return Swift.min(max, Swift.max(min, value))
    }

    private static func isPlausibleStoredSize(_ size: NSSize, maxSize: NSSize) -> Bool {
        guard size.width.isFinite, size.height.isFinite else { return false }
        guard size.width > 0, size.height > 0 else { return false }
        return size.width <= maxSize.width * 2 && size.height <= maxSize.height * 2
    }

    private static func axisSize(
        measured: CGFloat,
        current: CGFloat,
        minLength: CGFloat,
        maxLength: CGFloat,
        pad: CGFloat,
        allowShrink: Bool
    ) -> CGFloat {
        let padded = measured + pad
        if measured > current + 1 {
            return clamp(padded, min: minLength, max: maxLength)
        }
        if allowShrink && padded < current - 4 {
            return clamp(padded, min: minLength, max: maxLength)
        }
        return current
    }

    private static func xKey(_ id: String) -> String { "panel.\(id).x" }
    private static func yKey(_ id: String) -> String { "panel.\(id).y" }
    private static func widthKey(_ id: String) -> String { "panel.\(id).width" }
    private static func heightKey(_ id: String) -> String { "panel.\(id).height" }
    private static func userSizedKey(_ id: String) -> String { "panel.\(id).userSized" }
    private static func generationKey(_ id: String) -> String { "panel.\(id).frameGeneration" }
    private static let networkWidth320Key = "panel.network.widthMigrated320"
}
