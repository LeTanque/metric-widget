import SwiftUI

struct NetworkPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false

    var body: some View {
        let snap = store.snapshot
        let pad: CGFloat = embedded ? 8 : 10
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                RateLabel(
                    title: "DN",
                    value: ByteFormat.perSecond(snap.downloadBytesPerSec),
                    peak: ByteFormat.perSecond(snap.peakDownloadBytesPerSec),
                    indicator: ArcadeTileChrome.download
                )
                RateLabel(
                    title: "UP",
                    value: ByteFormat.perSecond(snap.uploadBytesPerSec),
                    peak: ByteFormat.perSecond(snap.peakUploadBytesPerSec),
                    indicator: ArcadeTileChrome.upload
                )
            }
            .padding(.horizontal, pad)
            .padding(.top, pad)
            .padding(.bottom, 8)

            NetworkSparkline(points: snap.networkHistory)
                .frame(maxWidth: .infinity)
                .frame(minHeight: embedded ? 28 : 32)
                .frame(maxHeight: embedded ? 36 : .infinity)

            VStack(alignment: .leading, spacing: 2) {
                ArcadeLabeledRow(label: "Interface", value: snap.interfaceName)
                ArcadeLabeledRow(label: "Computer IP", value: snap.localIP)
                ArcadeLabeledRow(label: "Outside IP", value: snap.publicIP)
            }
            .padding(.horizontal, pad)
            .padding(.top, 8)
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
            ArcadeFont.register()
        }
    }
}

private struct RateLabel: View {
    let title: String
    let value: String
    let peak: String
    let indicator: Color

    var body: some View {
        let parts = Self.splitRate(value)
        let peakParts = Self.splitRate(peak)
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title == "UP" ? "▲" : "▼")
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(indicator)
                Text(title)
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(ArcadeTileChrome.label)
            }
            HStack(alignment: .center, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(parts.number)
                        .font(ArcadeFont.font(size: 11))
                        .foregroundStyle(ArcadeTileChrome.value)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    if !parts.unit.isEmpty {
                        Text(parts.unit)
                            .font(ArcadeFont.font(size: 8))
                            .foregroundStyle(ArcadeTileChrome.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .layoutPriority(1)
                VStack(alignment: .leading, spacing: 1) {
                    Text("PEAK")
                        .font(ArcadeFont.font(size: 5))
                        .foregroundStyle(ArcadeTileChrome.label)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(peakParts.number)
                            .font(ArcadeFont.font(size: 6))
                            .foregroundStyle(ArcadeTileChrome.value)
                            .monospacedDigit()
                        if !peakParts.unit.isEmpty {
                            Text(peakParts.unit)
                                .font(ArcadeFont.font(size: 5))
                                .foregroundStyle(ArcadeTileChrome.label)
                        }
                    }
                }
                .layoutPriority(-1)
                .minimumScaleFactor(0.55)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func splitRate(_ raw: String) -> (number: String, unit: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let space = trimmed.firstIndex(of: " ") else { return (trimmed, "") }
        return (String(trimmed[..<space]), String(trimmed[trimmed.index(after: space)...]))
    }
}

private struct NetworkSparkline: View {
    var points: [NetworkPoint]

    var body: some View {
        Canvas { context, size in
            ArcadePlot.drawBackground(context: &context, size: size)
            let peak = max(points.map { max($0.upload, $0.download) }.max() ?? 0, 1)
            strokeLine(points.map(\.download), color: ArcadeTileChrome.download, peak: peak, size: size, context: &context)
            strokeLine(points.map(\.upload), color: ArcadeTileChrome.upload, peak: peak, size: size, context: &context)
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
