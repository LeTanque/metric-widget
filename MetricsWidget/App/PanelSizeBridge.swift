import SwiftUI

@MainActor
@Observable
final class PanelSizeBridge {
    var onMeasure: ((CGSize) -> Void)?

    func report(_ size: CGSize) {
        guard size.width.isFinite, size.height.isFinite else { return }
        guard size.width > 0, size.height > 0 else { return }
        onMeasure?(size)
    }
}

private struct ReportPanelSize: ViewModifier {
    var bridge: PanelSizeBridge
    var mode: PanelContentMeasureMode

    func body(content: Content) -> some View {
        measuredContent(content)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onChange(of: geo.size, initial: true) { _, newValue in
                            guard newValue.width > 1, newValue.height > 1 else { return }
                            bridge.report(newValue)
                        }
                }
            }
    }

    @ViewBuilder
    private func measuredContent(_ content: Content) -> some View {
        switch mode {
        case .wrapBoth:
            content.fixedSize(horizontal: true, vertical: true)
        case .wrapWidthGrowHeight:
            content.fixedSize(horizontal: true, vertical: false)
        case .fillWidthGrowHeight:
            content.fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension View {
    @ViewBuilder
    func reportPanelContentSize(
        when enabled: Bool,
        bridge: PanelSizeBridge,
        mode: PanelContentMeasureMode = .wrapBoth
    ) -> some View {
        if enabled {
            modifier(ReportPanelSize(bridge: bridge, mode: mode))
        } else {
            self
        }
    }
}
