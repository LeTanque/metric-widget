import AppKit

@MainActor
final class MuralBackdropView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    var scrimAlpha: CGFloat = 0.55 {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var isOpaque: Bool { false }
    override var wantsDefaultClipping: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let image, let window else { return }
        let screenFrame: NSRect = (window.screen ?? NSScreen.main)?.frame ?? window.frame
        let source: NSRect = Self.sourceRect(
            imageSize: image.size,
            screenFrame: screenFrame,
            windowFrame: window.frame
        )
        image.draw(
            in: bounds,
            from: source,
            operation: .copy,
            fraction: 1.0,
            respectFlipped: true,
            hints: [
                .interpolation: NSImageInterpolation.high
            ]
        )
        NSColor.black.withAlphaComponent(scrimAlpha).setFill()
        bounds.fill(using: .sourceOver)
    }

    static func sourceRect(imageSize: NSSize, screenFrame: NSRect, windowFrame: NSRect) -> NSRect {
        let imageWidth: CGFloat = max(imageSize.width, 1)
        let imageHeight: CGFloat = max(imageSize.height, 1)
        let scale: CGFloat = max(screenFrame.width / imageWidth, screenFrame.height / imageHeight)
        let drawnWidth: CGFloat = imageWidth * scale
        let drawnHeight: CGFloat = imageHeight * scale
        let drawnOrigin: NSPoint = NSPoint(
            x: screenFrame.midX - drawnWidth / 2,
            y: screenFrame.midY - drawnHeight / 2
        )
        return NSRect(
            x: (windowFrame.minX - drawnOrigin.x) / scale,
            y: (windowFrame.minY - drawnOrigin.y) / scale,
            width: windowFrame.width / scale,
            height: windowFrame.height / scale
        )
    }
}
