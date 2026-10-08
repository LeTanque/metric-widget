import SwiftUI

enum ArcadeTileChrome {
    static let upload = Color(red: 0.86, green: 0.08, blue: 0.24)
    static let download = Color(red: 0.05, green: 0.55, blue: 1.0)
    static let accent = Color(red: 0.05, green: 0.55, blue: 1.0)
    static let warning = Color(red: 0.86, green: 0.08, blue: 0.24)
    static let label = Color(white: 0.56)
    static let value = Color.white
    static let plotFill = Color.black
    static let grid = Color.white.opacity(0.16)
    static let baseline = Color.white.opacity(0.34)
}

enum ArcadePlot {
    static func drawBackground(
        context: inout GraphicsContext,
        size: CGSize,
        rows: Int = 4,
        ticks: Int = 6
    ) {
        let plot = CGRect(origin: .zero, size: size)
        context.fill(Path(plot), with: .color(ArcadeTileChrome.plotFill))

        guard size.width > 1, size.height > 1 else { return }

        for index in 0...rows {
            let y = size.height * CGFloat(index) / CGFloat(rows)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: size.width, y: y))
            let isBaseline = index == rows
            context.stroke(
                line,
                with: .color(isBaseline ? ArcadeTileChrome.baseline : ArcadeTileChrome.grid),
                lineWidth: isBaseline ? 1 : 0.5
            )
        }

        for index in 0...ticks {
            let x = size.width * CGFloat(index) / CGFloat(ticks)
            var vertical = Path()
            vertical.move(to: CGPoint(x: x, y: 0))
            vertical.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(vertical, with: .color(ArcadeTileChrome.grid.opacity(0.55)), lineWidth: 0.4)

            var tick = Path()
            tick.move(to: CGPoint(x: x, y: size.height))
            tick.addLine(to: CGPoint(x: x, y: size.height - 3))
            context.stroke(tick, with: .color(ArcadeTileChrome.baseline), lineWidth: 0.7)
        }
    }

    static func fillColor(percent: Double, remaining: Bool) -> Color {
        if remaining {
            return percent <= 20 ? ArcadeTileChrome.warning : ArcadeTileChrome.accent
        }
        return percent >= 80 ? ArcadeTileChrome.warning : ArcadeTileChrome.accent
    }
}

struct ArcadePanelSurface<Content: View>: View {
    var embedded: Bool
    var wrapContentWidth: Bool = false
    var fillAvailableHeight: Bool = true
    @ViewBuilder var content: Content

    var body: some View {
        let pad: CGFloat = embedded ? 8 : 10
        content
            .padding(pad)
            .frame(
                maxWidth: wrapContentWidth ? nil : .infinity,
                maxHeight: (embedded || !fillAvailableHeight) ? nil : .infinity,
                alignment: .topLeading
            )
            .fixedSize(horizontal: wrapContentWidth, vertical: wrapContentWidth)
            .background {
                if embedded {
                    ChamferedRectangle().fill(Color.black.opacity(0.18))
                }
            }
            .chamferedTileShape()
            .onAppear {
                ArcadeFont.register()
            }
    }
}

struct ArcadeFittingPair<Label: View, Value: View>: View {
    var showsValue: Bool = true
    @ViewBuilder var label: () -> Label
    @ViewBuilder var value: () -> Value

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                label()
                    .fixedSize(horizontal: true, vertical: true)
                Spacer(minLength: 6)
                if showsValue {
                    value()
                        .fixedSize(horizontal: true, vertical: true)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                label()
                    .fixedSize(horizontal: false, vertical: true)
                if showsValue {
                    value()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ArcadeLabeledRow: View {
    let label: String
    let value: String
    var valueColor: Color = ArcadeTileChrome.value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(ArcadeFont.font(size: 7))
                .foregroundStyle(ArcadeTileChrome.label)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 6)
            Text(value)
                .font(ArcadeFont.font(size: 8))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .textSelection(.enabled)
        }
    }
}

struct ArcadeDiskMeter: View {
    var used: UInt64
    var total: UInt64

    var body: some View {
        let fraction = total > 0 ? min(max(Double(used) / Double(total), 0), 1) : 0
        let percent = fraction * 100
        let color = ArcadePlot.fillColor(percent: percent, remaining: false)
        Canvas { context, size in
            ArcadePlot.drawBackground(context: &context, size: size, rows: 4, ticks: 4)
            let radius = min(size.width, size.height) * 0.34
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var track = Path()
            track.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(360),
                clockwise: false
            )
            context.stroke(track, with: .color(ArcadeTileChrome.grid), style: StrokeStyle(lineWidth: 7))
            if fraction > 0 {
                var usedPath = Path()
                usedPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * fraction),
                    clockwise: false
                )
                context.stroke(usedPath, with: .color(color), style: StrokeStyle(lineWidth: 7, lineCap: .butt))
            }
        }
        .overlay {
            VStack(spacing: 2) {
                Text("DISK")
                    .font(ArcadeFont.font(size: 6))
                    .foregroundStyle(ArcadeTileChrome.label)
                Text(total > 0 ? "\(Int(percent.rounded()))%" : "—")
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(ArcadeTileChrome.value)
                    .monospacedDigit()
            }
        }
    }
}

struct PanelChrome<Content: View>: View {
    let title: String
    let symbol: String
    var compact: Bool = false
    /// When true, panel width follows content instead of stretching with the window.
    var wrapContentWidth: Bool = false
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
        .frame(maxWidth: wrapContentWidth ? nil : .infinity, alignment: .topLeading)
        .fixedSize(horizontal: wrapContentWidth, vertical: !compact)
        .foregroundStyle(p.primary)
        .background(.clear)
    }
}

struct MeterBar: View {
    let title: String
    let percent: Double
    let detail: String
    var remaining: Bool = false
    var detailColor: Color = ArcadeTileChrome.value
    var compact: Bool = false
    var wrapWhenTight: Bool = false

    var body: some View {
        let clamped = min(max(percent, 0), 100)
        let fill = ArcadePlot.fillColor(percent: clamped, remaining: remaining)
        let titleSize: CGFloat = compact ? 6 : 7
        let valueSize: CGFloat = compact ? 7 : 8

        VStack(alignment: .leading, spacing: 3) {
            if wrapWhenTight {
                ArcadeFittingPair(showsValue: !detail.isEmpty) {
                    Text(title.uppercased())
                        .font(ArcadeFont.font(size: titleSize))
                        .foregroundStyle(ArcadeTileChrome.label)
                } value: {
                    Text(detail)
                        .font(ArcadeFont.font(size: titleSize))
                        .foregroundStyle(detailColor)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title.uppercased())
                        .font(ArcadeFont.font(size: titleSize))
                        .foregroundStyle(ArcadeTileChrome.label)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 6)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(ArcadeFont.font(size: titleSize))
                            .foregroundStyle(detailColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(-1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .center, spacing: 6) {
                Canvas { context, size in
                    ArcadePlot.drawBackground(context: &context, size: size, rows: 3, ticks: 8)
                    let width = size.width * CGFloat(clamped / 100)
                    if width > 0 {
                        let bar = Path(CGRect(x: 0, y: 2, width: width, height: max(size.height - 4, 1)))
                        context.fill(bar, with: .color(fill.opacity(0.85)))
                        var edge = Path()
                        edge.move(to: CGPoint(x: width, y: 1))
                        edge.addLine(to: CGPoint(x: width, y: size.height - 1))
                        context.stroke(edge, with: .color(fill), lineWidth: 1.2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 16)

                Text("\(Int(clamped.rounded()))%")
                    .font(ArcadeFont.font(size: valueSize))
                    .foregroundStyle(ArcadeTileChrome.value)
                    .monospacedDigit()
                    .frame(minWidth: 28, alignment: .trailing)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
