import SwiftUI

struct SystemPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let snap = store.snapshot
        let chrome = themes.palette.arcade
        ArcadePanelSurface(embedded: embedded) {
            VStack(alignment: .leading, spacing: embedded ? 10 : 12) {
                HStack(alignment: .center, spacing: 12) {
                    ArcadeDiskMeter(used: snap.diskUsedBytes, total: snap.diskTotalBytes)
                        .frame(width: embedded ? 72 : 84, height: embedded ? 72 : 84)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("STORAGE")
                            .font(ArcadeFont.font(size: 7))
                            .foregroundStyle(chrome.label)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(ByteFormat.bytes(snap.diskUsedBytes))
                                .font(ArcadeFont.font(size: 8))
                                .foregroundStyle(chrome.value)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                            Text("USED")
                                .font(ArcadeFont.font(size: 8))
                                .foregroundStyle(chrome.label)
                                .lineLimit(1)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(ByteFormat.bytes(snap.diskFreeBytes))
                                .font(ArcadeFont.font(size: 8))
                                .foregroundStyle(chrome.value)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                            Text("FREE")
                                .font(ArcadeFont.font(size: 8))
                                .foregroundStyle(chrome.label)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }

                MeterBar(
                    title: "CPU",
                    percent: snap.cpuPercent,
                    detail: "All cores",
                    detailColor: chrome.label
                )
                MeterBar(
                    title: "Memory",
                    percent: snap.ramPercent,
                    detail: "\(ByteFormat.bytes(snap.ramUsedBytes)) / \(ByteFormat.bytes(snap.ramTotalBytes))"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
