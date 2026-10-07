import AppKit
import SwiftUI

enum ClockPanelMetrics {
    static let scale: CGFloat = 1.2
    static let digitHeight: CGFloat = 22 * scale
    static let outerPadding: CGFloat = 8
    static let innerPaddingH: CGFloat = 12
    static let innerPaddingV: CGFloat = 8
    static let stackSpacing: CGFloat = 4
    static let timeMeridiemSpacing: CGFloat = 6
    static let meridiemColumnWidth: CGFloat = 22
    static let labelHeight: CGFloat = 12
    static let meridiemFontSize: CGFloat = 9 * scale
    static let labelFontSize: CGFloat = 8 * scale

    static var contentSize: NSSize {
        let timeWidth = LEDGlyphMetrics.timeWidth(height: digitHeight)
        let width = outerPadding * 2
            + innerPaddingH * 2
            + timeWidth
            + timeMeridiemSpacing
            + meridiemColumnWidth
        let height = outerPadding * 2
            + innerPaddingV * 2
            + digitHeight
            + stackSpacing
            + labelHeight
        return NSSize(width: ceil(width), height: ceil(height + 4))
    }
}

/// Desktop panel sizing — not tied to WidgetKit families (+20% vs prior compact bar).
enum ClockPanelWindowSize {
    static let size = NSSize(
        width: max(148 * ClockPanelMetrics.scale, ClockPanelMetrics.contentSize.width),
        height: ClockPanelMetrics.contentSize.height
    )
}

struct ClockPanelView: View {
    var zone: ClockTimeZoneChoice
    @Environment(ThemeStore.self) private var themes

    private var timeZone: TimeZone { zone.timeZone }

    private func calendar(at date: Date) -> Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }

    var body: some View {
        let p = themes.palette
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let date = context.date
            let cal = calendar(at: date)
            let isPM = cal.component(.hour, from: date) >= 12
            let meridiem = isPM ? "PM" : "AM"

            VStack(spacing: ClockPanelMetrics.stackSpacing) {
                HStack(alignment: .center, spacing: ClockPanelMetrics.timeMeridiemSpacing) {
                    LEDSevenSegmentTime(
                        date: date,
                        timeZone: timeZone,
                        ledColor: p.clockLED,
                        blinkColon: true,
                        digitHeight: ClockPanelMetrics.digitHeight,
                        segmentThickness: 1.25
                    )

                    VStack(spacing: 4) {
                        MeridiemIndicatorLight(isPM: isPM)
                        Text(meridiem)
                            .font(.system(size: ClockPanelMetrics.meridiemFontSize, weight: .heavy, design: .monospaced))
                            .foregroundStyle(p.clockLED.opacity(0.95))
                            .fixedSize()
                    }
                    .frame(width: ClockPanelMetrics.meridiemColumnWidth)
                }

                Text(zone.label)
                    .font(.system(size: ClockPanelMetrics.labelFontSize, weight: .heavy, design: .monospaced))
                    .foregroundStyle(p.primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, ClockPanelMetrics.innerPaddingH)
            .padding(.vertical, ClockPanelMetrics.innerPaddingV)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(ClockPanelMetrics.outerPadding)
        .frame(width: ClockPanelWindowSize.size.width, height: ClockPanelWindowSize.size.height)
    }
}

private struct MeridiemIndicatorLight: View {
    var isPM: Bool

    var body: some View {
        Circle()
            .fill(isPM ? Color.red : Color.red.opacity(0.18))
            .frame(width: 6, height: 6)
            .shadow(color: isPM ? Color.red.opacity(0.9) : .clear, radius: 3)
    }
}
