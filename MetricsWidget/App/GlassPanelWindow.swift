import AppKit
import SwiftUI

@MainActor
final class GlassPanelWindow: NSPanel, NSWindowDelegate {
    let panelID: String

    init<Content: View>(id: String, size: NSSize, rootView: Content) {
        self.panelID = id
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

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

        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = NSRect(origin: .zero, size: size)

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = 20
            glass.style = .regular
            glass.contentView = hosting
            contentView = glass
        } else {
            let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
            effect.material = .hudWindow
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.wantsLayer = true
            effect.layer?.cornerRadius = 20
            effect.layer?.masksToBounds = true
            hosting.autoresizingMask = [.width, .height]
            effect.addSubview(hosting)
            contentView = effect
        }

        setContentSize(size)
        restoreFrame(defaultSize: size)
        delegate = self
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    func windowDidMove(_ notification: Notification) {
        persistFrame()
    }

    private func restoreFrame(defaultSize: NSSize) {
        let defaults = UserDefaults.standard
        let xKey = "panel.\(panelID).x"
        let yKey = "panel.\(panelID).y"
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
            default: cascade = 24
            }
            let origin = NSPoint(
                x: screen.minX + cascade,
                y: screen.minY + 28
            )
            setFrameOrigin(origin)
        }
    }

    private func persistFrame() {
        UserDefaults.standard.set(frame.origin.x, forKey: "panel.\(panelID).x")
        UserDefaults.standard.set(frame.origin.y, forKey: "panel.\(panelID).y")
    }
}
