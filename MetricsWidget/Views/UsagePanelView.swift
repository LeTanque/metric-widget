import SwiftUI

struct UsagePanelView: View {
    var store: UsageStore
    var embedded: Bool = false

    var body: some View {
        ArcadePanelSurface(embedded: embedded) {
            VStack(alignment: .leading, spacing: 12) {
                if store.snapshot.providers.isEmpty {
                    Text("TURN ON CURSOR, GROK BOT, OPENAI, OR ANTHROPIC IN SETTINGS.")
                        .font(ArcadeFont.font(size: 6))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(store.snapshot.providers) { provider in
                        ProviderUsageBlock(provider: provider)
                    }
                }
                if let updated = store.snapshot.lastUpdated {
                    Text("UPDATED \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ProviderUsageBlock: View {
    let provider: ProviderUsage

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(provider.title.uppercased())
                    .font(ArcadeFont.font(size: 7))
                    .foregroundStyle(ArcadeTileChrome.value)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 6)
                if !provider.resetLabel.isEmpty {
                    Text(provider.resetLabel.uppercased())
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(-1)
                }
            }
            Text(provider.subtitle.uppercased())
                .font(ArcadeFont.font(size: 5))
                .foregroundStyle(ArcadeTileChrome.label)
                .lineLimit(1)
                .truncationMode(.tail)

            if let error = provider.error {
                Text(error)
                    .font(ArcadeFont.font(size: 6))
                    .foregroundStyle(ArcadeTileChrome.warning)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                if let percent = provider.percent {
                    MeterBar(
                        title: "Included spend remaining",
                        percent: percent,
                        detail: provider.detail,
                        remaining: true,
                        compact: true
                    )
                } else {
                    Text(provider.detail)
                        .font(ArcadeFont.font(size: 7))
                        .foregroundStyle(ArcadeTileChrome.value)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }

                if !provider.quotaLines.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(provider.quotaLines, id: \.self) { line in
                            MeterBar(
                                title: line.label,
                                percent: line.percentUsed,
                                detail: "",
                                compact: true
                            )
                        }
                    }
                    .padding(.top, 4)
                }

                if let footnote = provider.footnote {
                    Text(footnote)
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .padding(.top, 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
