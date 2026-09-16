import SwiftUI

struct PanelChrome<Content: View>: View {
    let title: String
    let symbol: String
    var compact: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(compact ? 0 : 14)
        .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity, alignment: .topLeading)
        .background(.clear)
    }
}

struct MeterBar: View {
    let title: String
    let percent: Double
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detail)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let clamped = min(max(percent, 0), 100)
                ZStack {
                    Capsule()
                        .fill(.quaternary)
                    Capsule()
                        .fill(Color.accentColor.opacity(0.88))
                        .frame(width: max(8, geo.size.width * CGFloat(clamped / 100)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(Int(clamped.rounded()))%")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(height: 20)
        }
    }
}
