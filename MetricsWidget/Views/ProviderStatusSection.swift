import SwiftUI

/// STATUS block at the bottom of the Usage tile: one line per enabled provider.
struct ProviderStatusSection: View {
    var status: ProviderStatusStore
    var inset: CGFloat
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let chrome = themes.palette.arcade
        VStack(alignment: .leading, spacing: 5) {
            SectionHeaderBand(inset: inset, flushTop: false) {
                Text("STATUS")
                    .font(ArcadeFont.font(size: 7))
                    .foregroundStyle(chrome.value)
            }
            ForEach(status.lines) { line in
                (Text("\(line.dot)  ").font(ArcadeFont.font(size: 6))
                    + Text(line.name.uppercased()).font(ArcadeFont.font(size: 6)).foregroundStyle(chrome.label)
                    + Text(" — ").font(ArcadeFont.font(size: 6)).foregroundStyle(chrome.label)
                    // Same style as the "CALENDAR MONTH · ORG COSTS" subtitle in UsagePanelView.
                    + Text(line.text).font(ArcadeFont.font(size: 5)).foregroundStyle(chrome.value))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
