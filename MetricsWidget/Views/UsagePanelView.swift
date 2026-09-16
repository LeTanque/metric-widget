import SwiftUI

struct UsagePanelView: View {
    var store: UsageStore
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        PanelChrome(title: "Usage", symbol: "circle.bottomhalf.filled", compact: embedded) {
            VStack(alignment: .leading, spacing: 12) {
                if store.snapshot.providers.isEmpty {
                    Text("Turn on Cursor, OpenAI, or Anthropic in Settings.")
                        .font(p.captionFont)
                        .foregroundStyle(p.secondary)
                } else {
                    ForEach(store.snapshot.providers) { provider in
                        ProviderUsageBlock(provider: provider)
                    }
                }
                if let updated = store.snapshot.lastUpdated {
                    Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(p.caption2Font)
                        .foregroundStyle(p.tertiary)
                }
            }
        }
    }
}

private struct ProviderUsageBlock: View {
    let provider: ProviderUsage
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(provider.title)
                    .font(p.captionFont.weight(.semibold))
                    .foregroundStyle(p.primary)
                Spacer()
                if !provider.resetLabel.isEmpty {
                    Text(provider.resetLabel)
                        .font(p.caption2Font)
                        .foregroundStyle(p.secondary)
                }
            }
            Text(provider.subtitle)
                .font(p.caption2Font)
                .foregroundStyle(p.secondary)
                .lineLimit(1)

            if let error = provider.error {
                Text(error)
                    .font(p.captionFont)
                    .foregroundStyle(p.warning)
            } else if let percent = provider.percent {
                MeterBar(title: provider.detail, percent: percent, detail: "")
            } else {
                Text(provider.detail)
                    .font(p.valueFont.weight(.medium))
                    .foregroundStyle(p.primary)
            }
        }
    }
}
