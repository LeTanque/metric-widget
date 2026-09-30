import SwiftUI

@MainActor
@Observable
final class PanelSizeBridge {
    var onMeasure: ((CGSize) -> Void)?

    func report(_ size: CGSize) {
        onMeasure?(size)
    }
}

private struct ReportPanelSize: ViewModifier {
    var bridge: PanelSizeBridge

    func body(content: Content) -> some View {
        content.background {
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.size, initial: true) { _, newValue in
                        bridge.report(newValue)
                    }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func reportPanelContentSize(when enabled: Bool, bridge: PanelSizeBridge) -> some View {
        if enabled {
            modifier(ReportPanelSize(bridge: bridge))
        } else {
            self
        }
    }
}
