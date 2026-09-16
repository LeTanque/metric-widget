import Charts
import SwiftUI

struct NetworkPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let snap = store.snapshot
        let p = themes.palette
        PanelChrome(title: "Network", symbol: "waveform.path.ecg", compact: embedded) {
            VStack(alignment: .leading, spacing: embedded ? 8 : 10) {
                HStack(alignment: .firstTextBaseline) {
                    RateLabel(title: "Down", value: ByteFormat.perSecond(snap.downloadBytesPerSec), color: p.down)
                    Spacer()
                    RateLabel(title: "Up", value: ByteFormat.perSecond(snap.uploadBytesPerSec), color: p.up)
                }

                Chart(snap.networkHistory) { point in
                    LineMark(
                        x: .value("t", point.id),
                        y: .value("Down", point.download),
                        series: .value("Dir", "Down")
                    )
                    .foregroundStyle(p.down)
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("t", point.id),
                        y: .value("Up", point.upload),
                        series: .value("Dir", "Up")
                    )
                    .foregroundStyle(p.up)
                    .interpolationMethod(.catmullRom)
                }
                .chartLegend(.hidden)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartPlotStyle { plot in
                    plot.background(.clear)
                }
                .frame(height: embedded ? 56 : 72)

                VStack(alignment: .leading, spacing: 3) {
                    LabeledValue(label: "Interface", value: snap.interfaceName)
                    LabeledValue(label: "Computer IP", value: snap.localIP)
                    LabeledValue(label: "Outside IP", value: snap.publicIP)
                }
            }
        }
    }
}

private struct RateLabel: View {
    let title: String
    let value: String
    let color: Color
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(p.caption2Font.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(p.bodyFont)
                .foregroundStyle(p.primary)
        }
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(p.captionFont)
                .foregroundStyle(p.secondary)
            Spacer()
            Text(value)
                .font(p.valueFont)
                .foregroundStyle(p.primary)
                .textSelection(.enabled)
        }
    }
}
