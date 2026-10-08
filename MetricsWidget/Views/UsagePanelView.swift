import SwiftUI

struct UsagePanelView: View {
    var store: UsageStore
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
                            flushTop: provider.id == store.snapshot.providers.first?.id
                        )
                    }
                }
                if let updated = store.snapshot.lastUpdated {
                    Text("UPDATED \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(chrome.label)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ProviderUsageBlock: View {
    let provider: ProviderUsage
    var inset: CGFloat
    var flushTop: Bool
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
                        title: "Included spend remaining",
                        percent: percent,
                        detail: provider.detail,
                        remaining: true,
                        compact: true,
                        wrapWhenTight: true
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
                            MeterBar(
                                title: line.label,
                                percent: line.percentUsed,
                                detail: "",
                                compact: true,
                                wrapWhenTight: true
                            )
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
