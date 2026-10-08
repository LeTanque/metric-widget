import SwiftUI

struct UsagePanelView: View {
    var store: UsageStore
    var embedded: Bool = false

    var body: some View {
        ArcadePanelSurface(embedded: embedded, wrapContentWidth: !embedded) {
            VStack(alignment: .leading, spacing: 12) {
                if store.snapshot.providers.isEmpty {
                    Text("TURN ON CURSOR, GROK BOT, OPENAI, OR ANTHROPIC IN SETTINGS.")
                        .font(ArcadeFont.font(size: 7))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(store.snapshot.providers) { provider in
                        ProviderUsageBlock(provider: provider)
                    }
                }
                if let updated = store.snapshot.lastUpdated {
                    Text("UPDATED \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(ArcadeFont.font(size: 6))
                        .foregroundStyle(ArcadeTileChrome.label)
                }
            }
        }
    }
}

private struct ProviderUsageBlock: View {
    let provider: ProviderUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(provider.title.uppercased())
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(ArcadeTileChrome.value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if !provider.resetLabel.isEmpty {
                    Text(provider.resetLabel.uppercased())
                        .font(ArcadeFont.font(size: 6))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            Text(provider.subtitle.uppercased())
                .font(ArcadeFont.font(size: 6))
                .foregroundStyle(ArcadeTileChrome.label)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let error = provider.error {
                Text(error)
                    .font(ArcadeFont.font(size: 7))
                    .foregroundStyle(ArcadeTileChrome.warning)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if let percent = provider.percent {
                    MeterBar(title: "Included spend remaining", percent: percent, detail: provider.detail, remaining: true)
                } else {
                    Text(provider.detail)
                        .font(ArcadeFont.font(size: 8))
                        .foregroundStyle(ArcadeTileChrome.value)
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                }

                if !provider.quotaLines.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(provider.quotaLines, id: \.self) { line in
                            MeterBar(
                                title: line.label,
                                percent: line.percentUsed,
                                detail: ""
                            )
                        }
                    }
                    .padding(.top, 4)
                }

                if let footnote = provider.footnote {
                    Text(footnote)
                        .font(ArcadeFont.font(size: 6))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .padding(.top, 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
