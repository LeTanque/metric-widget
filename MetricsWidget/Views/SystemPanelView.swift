import SwiftUI

struct SystemPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false

    var body: some View {
        let snap = store.snapshot
        ArcadePanelSurface(embedded: embedded) {
            VStack(alignment: .leading, spacing: embedded ? 10 : 12) {
                HStack(alignment: .center, spacing: 12) {
                    ArcadeDiskMeter(used: snap.diskUsedBytes, total: snap.diskTotalBytes)
                        .frame(width: embedded ? 72 : 84, height: embedded ? 72 : 84)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("STORAGE")
                            .font(ArcadeFont.font(size: 7))
                            .foregroundStyle(ArcadeTileChrome.label)
                        Text("\(ByteFormat.bytes(snap.diskUsedBytes)) used")
                            .font(ArcadeFont.font(size: 8))
                            .foregroundStyle(ArcadeTileChrome.value)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Text("\(ByteFormat.bytes(snap.diskFreeBytes)) free")
                            .font(ArcadeFont.font(size: 8))
                            .foregroundStyle(ArcadeTileChrome.value)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
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
}
