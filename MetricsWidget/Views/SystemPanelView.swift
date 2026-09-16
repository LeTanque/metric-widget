import Charts
import SwiftUI

struct SystemPanelView: View {
    var store: MetricsStore

    var body: some View {
        let snap = store.snapshot
        PanelChrome(title: "System", symbol: "gauge.with.dots.needle.67percent") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    Chart {
                        SectorMark(
                            angle: .value("Used", snap.diskUsedBytes),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.2
                        )
                        .foregroundStyle(Color.accentColor)
                        SectorMark(
                            angle: .value("Free", snap.diskFreeBytes),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.2
                        )
                        .foregroundStyle(Color.secondary.opacity(0.28))
                    }
                    .chartLegend(.hidden)
                    .frame(width: 92, height: 92)
                    .overlay {
                        VStack(spacing: 0) {
                            Text("Disk")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(usedPercent(snap))
                                .font(.caption.monospacedDigit().weight(.semibold))
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage")
                            .font(.caption.weight(.semibold))
                        Text("\(ByteFormat.bytes(snap.diskUsedBytes)) used")
                            .font(.caption.monospacedDigit())
                        Text("\(ByteFormat.bytes(snap.diskFreeBytes)) free")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                MeterBar(
                    title: "CPU",
                    percent: snap.cpuPercent,
                    detail: "All cores"
                )
                MeterBar(
                    title: "Memory",
                    percent: snap.ramPercent,
                    detail: "\(ByteFormat.bytes(snap.ramUsedBytes)) / \(ByteFormat.bytes(snap.ramTotalBytes))"
                )
            }
        }
    }

    private func usedPercent(_ snap: MetricsSnapshot) -> String {
        guard snap.diskTotalBytes > 0 else { return "—" }
        let percent = Double(snap.diskUsedBytes) / Double(snap.diskTotalBytes) * 100
        return "\(Int(percent.rounded()))%"
    }
}
