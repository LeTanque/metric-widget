import SwiftUI

private enum NetworkTileChrome {
    static let upload = Color(red: 0.05, green: 0.55, blue: 1.0)
    static let download = Color(red: 0.86, green: 0.08, blue: 0.24)
    static let label = Color(white: 0.56)
    static let value = Color.white
    static let plotFill = Color.black
    static let grid = Color.white.opacity(0.16)
    static let baseline = Color.white.opacity(0.34)
}

struct NetworkPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false

    var body: some View {
        let snap = store.snapshot
        let pad: CGFloat = embedded ? 8 : 10
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                RateLabel(
                    title: "DN",
                    value: ByteFormat.perSecond(snap.downloadBytesPerSec),
                    indicator: NetworkTileChrome.download
                )
                Spacer(minLength: 8)
                RateLabel(
                    title: "UP",
                    value: ByteFormat.perSecond(snap.uploadBytesPerSec),
                    indicator: NetworkTileChrome.upload,
                    alignment: .trailing
                )
            }
            .padding(.horizontal, pad)
            .padding(.top, pad)

            NetworkSparkline(points: snap.networkHistory)
                .frame(maxWidth: .infinity)
                .frame(minHeight: embedded ? 28 : 32)
                .frame(maxHeight: embedded ? 36 : .infinity)

            VStack(alignment: .leading, spacing: 2) {
                LabeledValue(label: "Interface", value: snap.interfaceName)
                LabeledValue(label: "Computer IP", value: snap.localIP)
                LabeledValue(label: "Outside IP", value: snap.publicIP)
            }
            .padding(.horizontal, pad)
            .padding(.bottom, pad)
        }
        .frame(maxWidth: .infinity, maxHeight: embedded ? nil : .infinity, alignment: .topLeading)
        .background {
            if embedded {
                ChamferedRectangle().fill(Color.black.opacity(0.18))
            }
        }
        .chamferedTileShape(border: embedded ? Color.white.opacity(0.22) : nil)
        .onAppear {
            NetworkArcadeFont.register()
        }
    }
}

private struct RateLabel: View {
    let title: String
    let value: String
    let indicator: Color
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        let parts = Self.splitRate(value)
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: 4) {
                Text(title == "UP" ? "▲" : "▼")
                    .font(NetworkArcadeFont.font(size: 8))
                    .foregroundStyle(indicator)
                Text(title)
                    .font(NetworkArcadeFont.font(size: 8))
                    .foregroundStyle(NetworkTileChrome.label)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(parts.number)
                    .font(NetworkArcadeFont.font(size: 11))
                    .foregroundStyle(NetworkTileChrome.value)
                    .monospacedDigit()
                if !parts.unit.isEmpty {
                    Text(parts.unit)
                        .font(NetworkArcadeFont.font(size: 8))
                        .foregroundStyle(NetworkTileChrome.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private static func splitRate(_ raw: String) -> (number: String, unit: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let space = trimmed.firstIndex(of: " ") else { return (trimmed, "") }
        return (String(trimmed[..<space]), String(trimmed[trimmed.index(after: space)...]))
    }
}

private struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label.uppercased())
                .font(NetworkArcadeFont.font(size: 7))
                .foregroundStyle(NetworkTileChrome.label)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength: 6)
            Text(value)
                .font(NetworkArcadeFont.font(size: 8))
                .foregroundStyle(NetworkTileChrome.value)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .textSelection(.enabled)
        }
    }
}

private struct NetworkSparkline: View {
    var points: [NetworkPoint]

    var body: some View {
        Canvas { context, size in
            let plot = CGRect(origin: .zero, size: size)
            context.fill(Path(plot), with: .color(NetworkTileChrome.plotFill))

            let rows = 4
            for index in 0...rows {
                let y = size.height * CGFloat(index) / CGFloat(rows)
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                let isBaseline = index == rows
                context.stroke(
                    line,
                    with: .color(isBaseline ? NetworkTileChrome.baseline : NetworkTileChrome.grid),
                    lineWidth: isBaseline ? 1 : 0.5
                )
            }

            let ticks = 6
            for index in 0...ticks {
                let x = size.width * CGFloat(index) / CGFloat(ticks)
                var vertical = Path()
                vertical.move(to: CGPoint(x: x, y: 0))
                vertical.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(vertical, with: .color(NetworkTileChrome.grid.opacity(0.55)), lineWidth: 0.4)

                var tick = Path()
                tick.move(to: CGPoint(x: x, y: size.height))
                tick.addLine(to: CGPoint(x: x, y: size.height - 3))
                context.stroke(tick, with: .color(NetworkTileChrome.baseline), lineWidth: 0.7)
            }

            let peak = max(points.map { max($0.upload, $0.download) }.max() ?? 0, 1)
            strokeLine(points.map(\.download), color: NetworkTileChrome.download, peak: peak, size: size, context: &context)
            strokeLine(points.map(\.upload), color: NetworkTileChrome.upload, peak: peak, size: size, context: &context)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func strokeLine(
        _ values: [Double],
        color: Color,
        peak: Double,
        size: CGSize,
        context: inout GraphicsContext
    ) {
        guard values.count > 1, size.width > 1, size.height > 1 else { return }
        var path = Path()
        let last = CGFloat(values.count - 1)
        for (index, value) in values.enumerated() {
            let x = size.width * CGFloat(index) / last
            let y = size.height - size.height * CGFloat(max(value, 0) / peak)
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))
    }
}
