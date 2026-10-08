import AppKit

enum PanelSnap {
    static let gap: CGFloat = 4
    static let threshold: CGFloat = 10
}

@MainActor
enum PanelSnapper {
    static func origin(for window: GlassPanelWindow) -> NSPoint {
        let moving = window.frame
        var xTargets: [(CGFloat, CGFloat)] = []
        var yTargets: [(CGFloat, CGFloat)] = []

        if let visible = (window.screen ?? NSScreen.main)?.visibleFrame {
            consider(&xTargets, current: moving.origin.x, target: visible.minX + PanelSnap.gap)
            consider(&xTargets, current: moving.origin.x, target: visible.maxX - PanelSnap.gap - moving.width)
            consider(&yTargets, current: moving.origin.y, target: visible.minY + PanelSnap.gap)
            consider(&yTargets, current: moving.origin.y, target: visible.maxY - PanelSnap.gap - moving.height)
        }

        for other in neighbors(of: window) {
            let frame = other.frame
            consider(&xTargets, current: moving.origin.x, target: frame.minX - PanelSnap.gap - moving.width)
            consider(&xTargets, current: moving.origin.x, target: frame.maxX + PanelSnap.gap)
            consider(&xTargets, current: moving.origin.x, target: frame.minX)
            consider(&xTargets, current: moving.origin.x, target: frame.maxX - moving.width)
            consider(&yTargets, current: moving.origin.y, target: frame.minY - PanelSnap.gap - moving.height)
            consider(&yTargets, current: moving.origin.y, target: frame.maxY + PanelSnap.gap)
            consider(&yTargets, current: moving.origin.y, target: frame.minY)
            consider(&yTargets, current: moving.origin.y, target: frame.maxY - moving.height)
        }

        var origin = moving.origin
        if let best = xTargets.min(by: { $0.1 < $1.1 }) {
            origin.x = best.0
        }
        if let best = yTargets.min(by: { $0.1 < $1.1 }) {
            origin.y = best.0
        }
        return origin
    }

    private static func consider(
        _ targets: inout [(CGFloat, CGFloat)],
        current: CGFloat,
        target: CGFloat
    ) {
        let distance = abs(target - current)
        guard distance <= PanelSnap.threshold else { return }
        targets.append((target, distance))
    }

    private static func neighbors(of window: GlassPanelWindow) -> [GlassPanelWindow] {
        NSApplication.shared.windows.compactMap { other in
            guard let panel = other as? GlassPanelWindow else { return nil }
            guard panel !== window, panel.isVisible else { return nil }
            guard panel.screen == window.screen else { return nil }
            return panel
        }
    }
}
