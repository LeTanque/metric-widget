import SwiftUI

struct AppMemoryPanelView: View {
    var store: MetricsStore

    var body: some View {
        let snap = store.snapshot
        PanelChrome(title: "App Memory", symbol: "memorychip") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Top RSS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ByteFormat.bytes(snap.processMemoryTotal))
                        .font(.caption.monospacedDigit().weight(.medium))
                }

                if snap.processes.isEmpty {
                    Text("Collecting…")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
                } else {
                    VStack(spacing: 5) {
                        ForEach(snap.processes) { process in
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
