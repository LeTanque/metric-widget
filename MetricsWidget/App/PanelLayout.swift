import AppKit

enum PanelContentMeasureMode {
    /// Shrink-wrap width and height (clock).
    case wrapBoth
    /// Intrinsic width; height follows content (usage).
    case wrapWidthGrowHeight
}

struct PanelLayout {
    var defaultSize: NSSize
    var minSize: NSSize
    var maxSize: NSSize
    var resizable: Bool
    /// Grow (and optionally shrink when not user-resized) to SwiftUI content measurements.
    var sizesToContent: Bool
    var contentMeasureMode: PanelContentMeasureMode = .wrapBoth
    var frameGeneration: Int = 1

    static let network = PanelLayout(
        defaultSize: NSSize(width: 249, height: 128),
        minSize: NSSize(width: 220, height: 120),
        maxSize: NSSize(width: 390, height: 200),
        resizable: true,
        sizesToContent: false,
        frameGeneration: 3
    )
    static let memory = PanelLayout(
        defaultSize: NSSize(width: 320, height: 268),
        minSize: NSSize(width: 260, height: 180),
        maxSize: NSSize(width: 520, height: 420),
        resizable: true,
        sizesToContent: false,
        frameGeneration: 2
    )
    static let system = PanelLayout(
        defaultSize: NSSize(width: 320, height: 252),
        minSize: NSSize(width: 260, height: 180),
        maxSize: NSSize(width: 520, height: 400),
        resizable: true,
        sizesToContent: false,
        frameGeneration: 2
    )
    static let combined = PanelLayout(
        defaultSize: NSSize(width: 700, height: 520),
        minSize: NSSize(width: 520, height: 380),
        maxSize: NSSize(width: 960, height: 760),
        resizable: true,
        sizesToContent: false,
        frameGeneration: 2
    )
    static let usage = PanelLayout(
        defaultSize: NSSize(width: 360, height: 340),
        minSize: NSSize(width: 300, height: 160),
        maxSize: NSSize(width: 460, height: 600),
        resizable: true,
        sizesToContent: true,
        contentMeasureMode: .wrapWidthGrowHeight,
        frameGeneration: 2
    )
    static let clock = PanelLayout(
        defaultSize: ClockPanelWindowSize.size,
        minSize: NSSize(width: 140, height: 48),
        maxSize: NSSize(width: 380, height: 120),
        resizable: true,
        sizesToContent: true,
        contentMeasureMode: .wrapBoth
    )
}
