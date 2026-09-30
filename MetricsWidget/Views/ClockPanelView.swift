import AppKit
import SwiftUI

private enum ClockPanelScale {
    static let factor: CGFloat = 1.2
}

/// Desktop panel sizing — not tied to WidgetKit families (+20% vs prior compact bar).
enum ClockPanelWindowSize {
    static let size = NSSize(width: 148 * ClockPanelScale.factor, height: 48 * ClockPanelScale.factor)
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

            VStack(spacing: 3 * ClockPanelScale.factor) {
                HStack(alignment: .center, spacing: 5) {
                    LEDSevenSegmentTime(
                        date: date,
                        timeZone: timeZone,
                        ledColor: p.clockLED,
                        blinkColon: true,
                        displayScale: ClockPanelScale.factor,
                        segmentThickness: 1.25
                    )
                    .layoutPriority(1)

                    VStack(spacing: 4) {
                        MeridiemIndicatorLight(isPM: isPM)
                        Text(meridiem)
                            .font(.system(size: 9 * ClockPanelScale.factor, weight: .heavy, design: .monospaced))
                            .foregroundStyle(p.clockLED.opacity(0.95))
                    }
                    .padding(.trailing, 2)
                }

                Text(zone.label)
                    .font(.system(size: 8 * ClockPanelScale.factor, weight: .heavy, design: .monospaced))
                    .foregroundStyle(p.primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 8 * ClockPanelScale.factor)
            .padding(.vertical, 4 * ClockPanelScale.factor)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(4)
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
