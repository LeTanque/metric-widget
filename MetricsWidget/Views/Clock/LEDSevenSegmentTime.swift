import SwiftUI

/// Classic 7-segment LED time (4 digits + colon), drawn in SwiftUI — no bundled font required.
struct LEDSevenSegmentTime: View {
    var date: Date
    var timeZone: TimeZone = .current
    var ledColor: Color
    var blinkColon: Bool = true
    var digitHeight: CGFloat
    var segmentThickness: CGFloat = 1

    private var colonLit: Bool {
        guard blinkColon else { return true }
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.component(.second, from: date) % 2 == 0
    }

    private var hourMinuteDigits: (hourTens: Int, hourOnes: Int, minuteTens: Int, minuteOnes: Int) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour24 = calendar.component(.hour, from: date)
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let minute = calendar.component(.minute, from: date)
        return (hour12 / 10, hour12 % 10, minute / 10, minute % 10)
    }

    private var digitSize: CGSize {
        LEDGlyphMetrics.digitSize(height: digitHeight)
    }

    private var colonSize: CGSize {
        LEDGlyphMetrics.colonSize(height: digitHeight)
    }

    var body: some View {
        let parts = hourMinuteDigits
        HStack(spacing: 0) {
            LEDDigit(
                digit: parts.hourTens,
                color: ledColor,
                blank: parts.hourTens == 0,
                size: digitSize,
                thicknessScale: segmentThickness
            )
            LEDDigit(
                digit: parts.hourOnes,
                color: ledColor,
                size: digitSize,
                thicknessScale: segmentThickness
            )
            LEDColon(color: ledColor, lit: colonLit, size: colonSize)
            LEDDigit(
                digit: parts.minuteTens,
                color: ledColor,
                size: digitSize,
                thicknessScale: segmentThickness
            )
            LEDDigit(
                digit: parts.minuteOnes,
                color: ledColor,
                size: digitSize,
                thicknessScale: segmentThickness
            )
        }
        .frame(
            width: LEDGlyphMetrics.timeWidth(height: digitHeight),
            height: digitHeight,
            alignment: .center
        )
    }
}

enum LEDGlyphMetrics {
    static let digitAspect: CGFloat = 0.58
    static let colonAspect: CGFloat = 0.35
    static let hourDigitSlots = 2
    static let minuteDigitSlots = 2

    static func digitSize(height: CGFloat) -> CGSize {
        CGSize(width: height * digitAspect, height: height)
    }

    static func colonSize(height: CGFloat) -> CGSize {
        CGSize(width: height * colonAspect, height: height)
    }

    static func timeWidth(height: CGFloat) -> CGFloat {
        digitSize(height: height).width * CGFloat(hourDigitSlots + minuteDigitSlots)
            + colonSize(height: height).width
    }
}

private struct LEDColon: View {
    var color: Color
    var lit: Bool = true
    var size: CGSize

    var body: some View {
        GeometryReader { geo in
            let base = min(geo.size.width, geo.size.height)
            let dot = max(base * 0.22, 4)
            let fill = lit ? color : ClockLEDChrome.off(color)
            VStack(spacing: geo.size.height * 0.18) {
                Circle().fill(fill).frame(width: dot, height: dot)
                Circle().fill(fill).frame(width: dot, height: dot)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct LEDDigit: View {
    var digit: Int
    var color: Color
    var blank: Bool = false
    var size: CGSize
    var thicknessScale: CGFloat = 1

    private var segments: UInt8 {
        guard !blank, digit >= 0, digit <= 9 else { return 0 }
        return Self.segmentMasks[digit]
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
        .frame(width: size.width, height: size.height)
    }

    private enum SegmentKind {
        case top, upperRight, lowerRight, bottom, lowerLeft, upperLeft, middle
    }

    @ViewBuilder
    private func segment(_ kind: SegmentKind, w: CGFloat, h: CGFloat, t: CGFloat, gap: CGFloat, on: Bool) -> some View {
        let fill = on ? color : ClockLEDChrome.off(color)
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
