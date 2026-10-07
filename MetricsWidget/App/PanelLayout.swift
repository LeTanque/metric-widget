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

    static let network = PanelLayout(
        defaultSize: NSSize(width: 332, height: 228),
        minSize: NSSize(width: 260, height: 160),
        maxSize: NSSize(width: 520, height: 400),
        resizable: true,
        sizesToContent: false
    )
    static let memory = PanelLayout(
        defaultSize: NSSize(width: 292, height: 268),
        minSize: NSSize(width: 240, height: 180),
        maxSize: NSSize(width: 480, height: 420),
        resizable: true,
        sizesToContent: false
    )
    static let system = PanelLayout(
        defaultSize: NSSize(width: 300, height: 248),
        minSize: NSSize(width: 240, height: 180),
        maxSize: NSSize(width: 480, height: 400),
        resizable: true,
        sizesToContent: false
    )
    static let combined = PanelLayout(
        defaultSize: NSSize(width: 640, height: 468),
        minSize: NSSize(width: 480, height: 360),
        maxSize: NSSize(width: 900, height: 720),
        resizable: true,
        sizesToContent: false
    )
    static let usage = PanelLayout(
        defaultSize: NSSize(width: 340, height: 320),
        minSize: NSSize(width: 280, height: 140),
        maxSize: NSSize(width: 420, height: 560),
        resizable: true,
        sizesToContent: true,
        contentMeasureMode: .wrapWidthGrowHeight
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
