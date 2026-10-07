import AppKit
import SwiftUI

/// WidgetKit `systemSmall` canvas (pt) — same reference as `~/git/clock-widget`.
enum ClockWidgetReference {
    static let systemSmallCanvas: CGFloat = 155

    /// LED digit height when sized like the default Clock widget tile time band.
    static var digitHeight: CGFloat {
        systemSmallCanvas * 0.35
    }
}

private enum ClockPanelTypography {
    static let locationPointSize: CGFloat = 8 * 1.1
    static let meridiemPointSize: CGFloat = 9
}

private enum ClockPanelChrome {
    static let stackSpacing: CGFloat = 2
    static let padH: CGFloat = 10
    static let padV: CGFloat = 4
}

/// Desktop panel sizing — content-driven; minimal vertical chrome.
enum ClockPanelWindowSize {
    static var size: NSSize {
        let digitH = ClockWidgetReference.digitHeight
        let timeW = LEDGlyphMetrics.timeWidth(height: digitH)
        let bottomRowH = max(
            ClockPanelTypography.locationPointSize + 1,
            ClockPanelTypography.meridiemPointSize + 2
        )
        let gaps = ClockPanelChrome.stackSpacing
        let padV = ClockPanelChrome.padV * 2
        return NSSize(
            width: timeW + ClockPanelChrome.padH * 2,
            height: digitH + gaps + bottomRowH + padV
        )
    }
}

struct ClockPanelView: View {
    var zone: ClockTimeZoneChoice
    @Environment(ThemeStore.self) private var themes

    private var timeZone: TimeZone { zone.timeZone }

    private var ledTimeWidth: CGFloat {
        LEDGlyphMetrics.timeWidth(height: ClockWidgetReference.digitHeight)
    }

    private func calendar(at date: Date) -> Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }

    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/d"
        return formatter.string(from: date)
    }

    var body: some View {
        let p = themes.palette
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let date = context.date
            let cal = calendar(at: date)
            let isPM = cal.component(.hour, from: date) >= 12
            let meridiem = isPM ? "PM" : "AM"

            VStack(alignment: .leading, spacing: ClockPanelChrome.stackSpacing) {
                HStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 0)
                    LEDSevenSegmentTime(
                        date: date,
                        timeZone: timeZone,
                        ledColor: p.clockLED,
                        blinkColon: true,
                        digitHeight: ClockWidgetReference.digitHeight,
                        segmentThickness: 1.25
                    )
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)

                HStack(alignment: .center, spacing: 0) {
                    Text(zone.label)
                        .font(
                            .system(
                                size: ClockPanelTypography.locationPointSize,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(p.primary.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 6)

                    Text(dateLabel(for: date))
                        .font(
                            .system(
                                size: ClockPanelTypography.locationPointSize,
                                weight: .heavy,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(p.secondary.opacity(0.9))
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    HStack(alignment: .center, spacing: 4) {
                        MeridiemIndicatorLight(isPM: isPM)
                        Text(meridiem)
                            .font(
                                .system(
                                    size: ClockPanelTypography.meridiemPointSize,
                                    weight: .heavy,
                                    design: .monospaced
                                )
                            )
                            .foregroundStyle(p.clockLED.opacity(0.95))
                    }
                }
            }
            .frame(minWidth: ledTimeWidth)
            .padding(.horizontal, ClockPanelChrome.padH)
            .padding(.vertical, ClockPanelChrome.padV)
            .fixedSize(horizontal: true, vertical: true)
        }
    }
}

private struct MeridiemIndicatorLight: View {
    var isPM: Bool

    var body: some View {
        Circle()
            .fill(isPM ? Color.red : Color.red.opacity(0.18))
            .frame(width: 5, height: 5)
            .shadow(color: isPM ? Color.red.opacity(0.9) : .clear, radius: 2)
    }
}
