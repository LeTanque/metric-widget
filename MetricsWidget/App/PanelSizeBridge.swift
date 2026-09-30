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
    @Environment(PanelSizeBridge.self) private var bridge

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
    func reportPanelContentSize(when enabled: Bool) -> some View {
        if enabled {
            modifier(ReportPanelSize())
        } else {
            self
        }
    }
}
