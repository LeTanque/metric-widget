import SwiftUI

struct AppMemoryPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    var rowLimit: Int = 8

    var body: some View {
        let snap = store.snapshot
        let rows = Array(snap.processes.prefix(rowLimit))
        ArcadePanelSurface(embedded: embedded) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeaderBand(inset: ArcadePanelSurface.inset(embedded: embedded)) {
                    ArcadeLabeledRow(
                        label: "Top RSS",
                        value: ByteFormat.bytes(snap.processMemoryTotal),
                        labelColor: ArcadeTileChrome.value
                    )
                }

                if rows.isEmpty {
                    Text("COLLECTING…")
                        .font(ArcadeFont.font(size: 7))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .frame(maxWidth: .infinity, minHeight: embedded ? 40 : 80, alignment: .center)
                } else {
                    VStack(spacing: 5) {
                        ForEach(rows) { process in
                            HStack(spacing: 8) {
                                Text(process.name)
                                    .font(ArcadeFont.font(size: 7))
                                    .foregroundStyle(ArcadeTileChrome.label)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                Spacer(minLength: 8)
                                Text(ByteFormat.bytes(process.rss))
                                    .font(ArcadeFont.font(size: 8))
                                    .foregroundStyle(ArcadeTileChrome.value)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                            }
                        }
                    }
                }
            }
        }
    }
}
