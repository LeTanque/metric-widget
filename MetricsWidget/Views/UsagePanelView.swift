import SwiftUI

struct UsagePanelView: View {
    var store: UsageStore
    var status: ProviderStatusStore? = nil
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let chrome = themes.palette.arcade
        ArcadePanelSurface(embedded: embedded, fillAvailableHeight: false) {
            VStack(alignment: .leading, spacing: 12) {
                if store.snapshot.providers.isEmpty {
                    Text("NO PROVIDERS CONFIGURED.")
                        .font(ArcadeFont.font(size: 6))
                        .foregroundStyle(chrome.label)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(store.snapshot.providers) { provider in
                        ProviderUsageBlock(
                            provider: provider,
                            inset: ArcadePanelMetrics.inset(embedded: embedded),
                            flushTop: provider.id == store.snapshot.providers.first?.id,
                            updated: ProviderUsageBlock.showsOwnUpdated(provider.id)
                                ? store.lastSuccess[provider.id] : nil
                        )
                    }
                }
                if let updated = store.snapshot.lastUpdated {
                    Text("UPDATED \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(chrome.label)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let status, status.enabled, !status.lines.isEmpty {
                    ProviderStatusSection(status: status, inset: ArcadePanelMetrics.inset(embedded: embedded))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ProviderUsageBlock: View {
    static func showsOwnUpdated(_ id: String) -> Bool { id == "cursor" || id == "grokbot" }

    let provider: ProviderUsage
    var inset: CGFloat
    var flushTop: Bool
    /// Last successful fetch for providers that show their own UPDATED line (Cursor, Grok Bot).
    var updated: Date? = nil
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let chrome = themes.palette.arcade
        VStack(alignment: .leading, spacing: 5) {
            SectionHeaderBand(inset: inset, flushTop: flushTop) {
                ArcadeFittingPair(showsValue: !provider.resetLabel.isEmpty) {
                    Text(provider.title.uppercased())
                        .font(ArcadeFont.font(size: 7))
                        .foregroundStyle(chrome.value)
                } value: {
                    Text(provider.resetLabel.uppercased())
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(chrome.label)
                }
            }
            Text(provider.subtitle.uppercased())
                .font(ArcadeFont.font(size: 5))
                .foregroundStyle(chrome.label)
                .fixedSize(horizontal: false, vertical: true)

            if let error = provider.error {
                Text(error)
                    .font(ArcadeFont.font(size: 6))
                    .foregroundStyle(chrome.warning)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if let percent = provider.percent {
                    MeterBar(
                        title: provider.meterTitle ?? "Included spend remaining",
                        percent: percent,
                        detail: provider.detail,
                        remaining: true,
                        compact: true,
                        wrapWhenTight: true,
                        usageThreshold: true
                    )
                } else {
                    Text(provider.detail)
                        .font(ArcadeFont.font(size: 7))
                        .foregroundStyle(chrome.value)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !provider.quotaLines.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(provider.quotaLines, id: \.self) { line in
                            VStack(alignment: .leading, spacing: 3) {
                                // Section name (subtitle style) keeps Cursor Models / Other Models distinct.
                                Text(line.label.uppercased())
                                    .font(ArcadeFont.font(size: 5))
                                    .foregroundStyle(chrome.label)
                                    .fixedSize(horizontal: false, vertical: true)
                                MeterBar(
                                    title: "Included spend remaining",
                                    percent: line.percentRemaining,
                                    detail: "",
                                    remaining: true,
                                    compact: true,
                                    wrapWhenTight: true,
                                    usageThreshold: true
                                )
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                if let footnote = provider.footnote {
                    Text(footnote)
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(chrome.label)
                        .padding(.top, 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let updated {
                // Same style as the OpenAI "UPDATED" line at the bottom of the tile.
                Text("UPDATED \(updated.formatted(date: .omitted, time: .shortened))")
                    .font(ArcadeFont.font(size: 5))
                    .foregroundStyle(chrome.label)
                    .padding(.top, 7)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
