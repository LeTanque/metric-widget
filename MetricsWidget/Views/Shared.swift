import SwiftUI

struct PanelChrome<Content: View>: View {
    let title: String
    let symbol: String
    var compact: Bool = false
    @ViewBuilder var content: Content
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(p.captionFont.weight(.semibold))
                    .foregroundStyle(p.secondary)
                Text(title)
                    .font(p.titleFont)
                    .foregroundStyle(p.secondary)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(compact ? 0 : 14)
        .frame(maxWidth: .infinity, maxHeight: compact ? nil : .infinity, alignment: .topLeading)
        .foregroundStyle(p.primary)
        .background(.clear)
    }
}

struct MeterBar: View {
    let title: String
    let percent: Double
    let detail: String
    private let segmentCount = 10

    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let p = themes.palette
        let clamped = min(max(percent, 0), 100)
        let lit = Int((clamped / 100 * Double(segmentCount)).rounded(.toNearestOrAwayFromZero))

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(p.captionFont)
                    .foregroundStyle(p.secondary)
                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(p.valueFont)
                        .foregroundStyle(p.secondary)
                }
            }
            HStack(alignment: .center, spacing: 8) {
                GeometryReader { geo in
                    let gap: CGFloat = 3
                    let totalGap = gap * CGFloat(segmentCount - 1)
                    let segmentWidth = max(2, (geo.size.width - totalGap) / CGFloat(segmentCount))

                    HStack(spacing: gap) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            let isLit = index < lit
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(isLit ? p.segmentOn : p.segmentOff)
                                .frame(width: segmentWidth)
                                .overlay {
                                    if isLit {
                                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        p.segmentOn.opacity(0.55),
                                                        p.segmentOn,
                                                        p.segmentOn.opacity(0.75)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    }
                                }
                                .shadow(
                                    color: p.segmentGlow && isLit ? p.segmentOn.opacity(0.85) : .clear,
                                    radius: p.segmentGlow ? 4 : 0
                                )
                                .shadow(
                                    color: p.segmentGlow && isLit ? p.segmentOn.opacity(0.45) : .clear,
                                    radius: p.segmentGlow ? 8 : 0
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(height: 22)

                Text("\(Int(clamped.rounded()))%")
                    .font(p.valueFont.weight(.semibold))
                    .foregroundStyle(p.barLabel)
                    .frame(minWidth: 34, alignment: .trailing)
            }
        }
    }
}
