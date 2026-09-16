import Charts
import SwiftUI

struct NetworkPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false

    var body: some View {
        let snap = store.snapshot
        PanelChrome(title: "Network", symbol: "waveform.path.ecg", compact: embedded) {
            VStack(alignment: .leading, spacing: embedded ? 8 : 10) {
                HStack(alignment: .firstTextBaseline) {
                    RateLabel(title: "Down", value: ByteFormat.perSecond(snap.downloadBytesPerSec), color: .blue)
                    Spacer()
                    RateLabel(title: "Up", value: ByteFormat.perSecond(snap.uploadBytesPerSec), color: .green)
                }

                Chart(snap.networkHistory) { point in
                    LineMark(
                        x: .value("t", point.id),
                        y: .value("Down", point.download),
                        series: .value("Dir", "Down")
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    LineMark(
                        x: .value("t", point.id),
                        y: .value("Up", point.upload),
                        series: .value("Dir", "Up")
                    )
                    .foregroundStyle(.green)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.callout.monospacedDigit().weight(.medium))
        }
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .textSelection(.enabled)
        }
    }
}
