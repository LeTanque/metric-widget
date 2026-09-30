import SwiftUI

/// Classic 7-segment LED time (HH:mm), drawn in SwiftUI — no bundled font required.
struct LEDSevenSegmentTime: View {
    var date: Date
    var timeZone: TimeZone = .current
    var ledColor: Color
    var blinkColon: Bool = true
    var displayScale: CGFloat = 1
    var segmentThickness: CGFloat = 1

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private var colonLit: Bool {
        guard blinkColon else { return true }
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.component(.second, from: date) % 2 == 0
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(timeText.enumerated()), id: \.offset) { _, char in
                if char == ":" {
                    LEDColon(color: ledColor, lit: colonLit)
                } else if let digit = char.wholeNumberValue {
                    LEDDigit(digit: digit, color: ledColor, thicknessScale: segmentThickness)
                }
            }
        }
        .scaleEffect(displayScale, anchor: .leading)
    }
}

private struct LEDColon: View {
    var color: Color
    var lit: Bool = true

    var body: some View {
        GeometryReader { geo in
            let dot = min(geo.size.width, geo.size.height) * 0.14
            let fill = lit ? color : color.opacity(0.07)
            VStack(spacing: geo.size.height * 0.22) {
                Circle().fill(fill).frame(width: dot, height: dot)
                Circle().fill(fill).frame(width: dot, height: dot)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(0.35, contentMode: .fit)
    }
}

private struct LEDDigit: View {
    var digit: Int
    var color: Color
    var thicknessScale: CGFloat = 1

    private var segments: UInt8 {
        Self.segmentMasks[digit]
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let t = min(w, h) * 0.11 * thicknessScale
            let gap = t * 0.35
            ZStack {
                segment(.top, w: w, h: h, t: t, gap: gap, on: segments & 0b1000000 != 0)
                segment(.upperRight, w: w, h: h, t: t, gap: gap, on: segments & 0b0100000 != 0)
                segment(.lowerRight, w: w, h: h, t: t, gap: gap, on: segments & 0b0010000 != 0)
                segment(.bottom, w: w, h: h, t: t, gap: gap, on: segments & 0b0001000 != 0)
                segment(.lowerLeft, w: w, h: h, t: t, gap: gap, on: segments & 0b0000100 != 0)
                segment(.upperLeft, w: w, h: h, t: t, gap: gap, on: segments & 0b0000010 != 0)
                segment(.middle, w: w, h: h, t: t, gap: gap, on: segments & 0b0000001 != 0)
            }
        }
        .aspectRatio(0.58, contentMode: .fit)
    }

    private enum SegmentKind {
        case top, upperRight, lowerRight, bottom, lowerLeft, upperLeft, middle
    }

    @ViewBuilder
    private func segment(_ kind: SegmentKind, w: CGFloat, h: CGFloat, t: CGFloat, gap: CGFloat, on: Bool) -> some View {
        let fill = on ? color : color.opacity(0.07)
        let glow = on ? color.opacity(0.55) : .clear
        switch kind {
        case .top:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: w - 2 * t - 2 * gap, height: t)
                .position(x: w / 2, y: t / 2 + gap)
        case .upperRight:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: t, height: (h - 3 * t - 4 * gap) / 2)
                .position(x: w - t / 2 - gap, y: (h - t) / 4 + t / 2 + gap)
        case .lowerRight:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: t, height: (h - 3 * t - 4 * gap) / 2)
                .position(x: w - t / 2 - gap, y: h - (h - t) / 4 - t / 2 - gap)
        case .bottom:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: w - 2 * t - 2 * gap, height: t)
                .position(x: w / 2, y: h - t / 2 - gap)
        case .lowerLeft:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: t, height: (h - 3 * t - 4 * gap) / 2)
                .position(x: t / 2 + gap, y: h - (h - t) / 4 - t / 2 - gap)
        case .upperLeft:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: t, height: (h - 3 * t - 4 * gap) / 2)
                .position(x: t / 2 + gap, y: (h - t) / 4 + t / 2 + gap)
        case .middle:
            Capsule().fill(fill).shadow(color: glow, radius: t * 0.6)
                .frame(width: w - 2 * t - 2 * gap, height: t)
                .position(x: w / 2, y: h / 2)
        }
    }

    private static let segmentMasks: [UInt8] = [
        0b1111110,
        0b0110000,
        0b1101101,
        0b1111001,
        0b0110011,
        0b1011011,
        0b1011111,
        0b1110000,
        0b1111111,
        0b1111011,
    ]
}
