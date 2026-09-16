import Charts
import SwiftUI

struct SystemPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let snap = store.snapshot
        let p = themes.palette
        PanelChrome(title: "System", symbol: "gauge.with.dots.needle.67percent", compact: embedded) {
            VStack(alignment: .leading, spacing: embedded ? 10 : 12) {
                HStack(alignment: .center, spacing: 14) {
                    Chart {
                        SectorMark(
                            angle: .value("Used", snap.diskUsedBytes),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.2
                        )
                        .foregroundStyle(p.accent)
                        SectorMark(
                            angle: .value("Free", snap.diskFreeBytes),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.2
                        )
                        .foregroundStyle(p.track)
                    }
                    .chartLegend(.hidden)
                    .frame(width: embedded ? 76 : 92, height: embedded ? 76 : 92)
                    .overlay {
                        VStack(spacing: 0) {
                            Text("Disk")
                                .font(p.caption2Font)
                                .foregroundStyle(p.secondary)
                            Text(usedPercent(snap))
                                .font(p.valueFont.weight(.semibold))
                                .foregroundStyle(p.primary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage")
                            .font(p.captionFont.weight(.semibold))
                            .foregroundStyle(p.primary)
                        Text("\(ByteFormat.bytes(snap.diskUsedBytes)) used")
                            .font(p.valueFont)
                            .foregroundStyle(p.primary)
                        Text("\(ByteFormat.bytes(snap.diskFreeBytes)) free")
                            .font(p.valueFont)
                            .foregroundStyle(p.secondary)
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
