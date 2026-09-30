import AppKit

struct PanelLayout {
    var defaultSize: NSSize
    var minSize: NSSize
    var resizable: Bool
    /// Grow (and optionally shrink when not user-resized) to SwiftUI content measurements.
    var sizesToContent: Bool

    static let network = PanelLayout(
        defaultSize: NSSize(width: 332, height: 228),
        minSize: NSSize(width: 260, height: 160),
        resizable: true,
        sizesToContent: false
    )
    static let memory = PanelLayout(
        defaultSize: NSSize(width: 292, height: 268),
        minSize: NSSize(width: 240, height: 180),
        resizable: true,
        sizesToContent: false
    )
    static let system = PanelLayout(
        defaultSize: NSSize(width: 300, height: 248),
        minSize: NSSize(width: 240, height: 180),
        resizable: true,
        sizesToContent: false
    )
    static let combined = PanelLayout(
        defaultSize: NSSize(width: 640, height: 468),
        minSize: NSSize(width: 480, height: 360),
        resizable: true,
        sizesToContent: false
    )
    static let usage = PanelLayout(
        defaultSize: NSSize(width: 340, height: 320),
        minSize: NSSize(width: 280, height: 140),
        resizable: true,
        sizesToContent: true
    )
    static let clock = PanelLayout(
        defaultSize: ClockPanelWindowSize.size,
        minSize: NSSize(width: 120, height: 44),
        resizable: true,
        sizesToContent: true
    )
}
