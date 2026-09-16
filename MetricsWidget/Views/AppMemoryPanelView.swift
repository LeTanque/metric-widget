import SwiftUI

struct AppMemoryPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    var rowLimit: Int = 8
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let snap = store.snapshot
        let rows = Array(snap.processes.prefix(rowLimit))
        let p = themes.palette
        PanelChrome(title: "App Memory", symbol: "memorychip", compact: embedded) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Top RSS")
                        .font(p.captionFont)
                        .foregroundStyle(p.secondary)
                    Spacer()
                    Text(ByteFormat.bytes(snap.processMemoryTotal))
                        .font(p.valueFont.weight(.medium))
                        .foregroundStyle(p.primary)
                }

                if rows.isEmpty {
                    Text("Collecting…")
                        .font(p.captionFont)
                        .foregroundStyle(p.tertiary)
                        .frame(maxWidth: .infinity, minHeight: embedded ? 40 : 80, alignment: .center)
                } else {
                    VStack(spacing: 5) {
                        ForEach(rows) { process in
                            HStack(spacing: 8) {
                                Text(process.name)
                                    .font(p.captionFont)
                                    .foregroundStyle(p.primary)
                                    .lineLimit(1)
                                Spacer(minLength: 8)
                                Text(ByteFormat.bytes(process.rss))
                                    .font(p.valueFont)
                                    .foregroundStyle(p.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
