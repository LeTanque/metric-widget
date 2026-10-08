import Foundation
import SwiftUI

struct NetworkPanelView: View {
    var store: MetricsStore
    var embedded: Bool = false
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let snap = store.snapshot
        let chrome = themes.palette.arcade
        let pad: CGFloat = embedded ? 8 : 10
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                RateLabel(
                    title: "DN",
                    bytesPerSec: snap.downloadBytesPerSec,
                    peakBytesPerSec: snap.peakDownloadBytesPerSec,
                    indicator: chrome.download
                )
                Spacer(minLength: 8)
                RateLabel(
                    title: "UP",
                    bytesPerSec: snap.uploadBytesPerSec,
                    peakBytesPerSec: snap.peakUploadBytesPerSec,
                    indicator: chrome.upload,
                    alignment: .trailing
                )
            }
            .padding(.horizontal, pad)
            .padding(.top, pad)
            .padding(.bottom, 8)

            NetworkSparkline(points: snap.networkHistory, chrome: chrome)
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
        .chamferedTileShape()
        .onAppear {
            ArcadeFont.register()
        }
    }
}

private struct RateLabel: View {
    let title: String
    let bytesPerSec: Double
    let peakBytesPerSec: Double
    let indicator: Color
    var alignment: HorizontalAlignment = .leading
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: 4) {
                Text(title == "UP" ? "▲" : "▼")
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(indicator)
                Text(title)
                    .font(ArcadeFont.font(size: 8))
                    .foregroundStyle(themes.palette.arcade.label)
            }
            LEDRateValue(bytesPerSec: bytesPerSec, numberSize: 11, unitSize: 8)
            Text("PEAK")
                .font(ArcadeFont.font(size: 6))
                .foregroundStyle(themes.palette.arcade.label)
            LEDRateValue(bytesPerSec: peakBytesPerSec, numberSize: 10, unitSize: 7)
        }
    }
}

private struct LEDRateValue: View {
    let bytesPerSec: Double
    let numberSize: CGFloat
    let unitSize: CGFloat
    @Environment(ThemeStore.self) private var themes

    var body: some View {
        let parts = Self.rateParts(bytesPerSec)
        let slot = Self.ledSlot(parts.number)
        let on = themes.palette.clockLED
        let off = themes.palette.clockLEDOff
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            HStack(spacing: 0) {
                ForEach(Array(slot.padded.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(ArcadeFont.font(size: numberSize))
                        .foregroundStyle(index < slot.padCount ? off : on)
                        .frame(width: numberSize, alignment: .center)
                }
            }
            if !parts.unit.isEmpty {
                Text(parts.unit)
                    .font(ArcadeFont.font(size: unitSize))
                    .foregroundStyle(themes.palette.arcade.label)
                    .lineLimit(1)
            }
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private static func rateParts(_ bytesPerSec: Double) -> (number: String, unit: String) {
        let raw = ByteFormat.perSecond(bytesPerSec)
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let number: String
        let unit: String
        if let space = trimmed.firstIndex(of: " ") {
            number = String(trimmed[..<space])
            unit = String(trimmed[trimmed.index(after: space)...])
        } else {
            number = trimmed
            unit = ""
        }
        let cleaned = number.replacingOccurrences(of: ",", with: "")
        let numeric = cleaned.unicodeScalars.allSatisfy { CharacterSet.decimalDigits.contains($0) || $0 == "." }
        return (numeric && !cleaned.isEmpty ? cleaned : "0", unit)
    }

    private static func ledSlot(_ number: String, width: Int = 4) -> (padded: [Character], padCount: Int) {
        if number.count >= width {
            return (Array(number.prefix(width)), 0)
        }
        let padCount = width - number.count
        return (Array(String(repeating: "0", count: padCount) + number), padCount)
    }
}

private struct NetworkSparkline: View {
    var points: [NetworkPoint]
    var chrome: ArcadeChrome

    var body: some View {
        Canvas { context, size in
            ArcadePlot.drawBackground(context: &context, size: size, chrome: chrome)
            let peak = max(points.map { max($0.upload, $0.download) }.max() ?? 0, 1)
            strokeLine(points.map(\.download), color: chrome.download, peak: peak, size: size, context: &context)
            strokeLine(points.map(\.upload), color: chrome.upload, peak: peak, size: size, context: &context)
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
