import SwiftUI

struct AppMemoryPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    var rowLimit: Int = 8

    var body: some View {
        let snap = store.snapshot
        let rows = Array(snap.processes.prefix(rowLimit))
        PanelChrome(title: "App Memory", symbol: "memorychip", compact: embedded) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Top RSS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ByteFormat.bytes(snap.processMemoryTotal))
                        .font(.caption.monospacedDigit().weight(.medium))
                }

                if rows.isEmpty {
                    Text("Collecting…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: embedded ? 40 : 80, alignment: .center)
                } else {
                    VStack(spacing: 5) {
                        ForEach(rows) { process in
                            HStack(spacing: 8) {
                                Text(process.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text(ByteFormat.bytes(process.rss))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
