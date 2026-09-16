import Foundation

struct ProviderUsage: Identifiable, Sendable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var detail: String
    var percent: Double?
    var resetLabel: String
    var error: String?

    static func placeholder(id: String, title: String, message: String) -> ProviderUsage {
        ProviderUsage(
            id: id,
            title: title,
            subtitle: "Not configured",
            detail: message,
            percent: nil,
            resetLabel: "",
            error: nil
        )
    }
}

struct UsageSnapshot: Sendable {
    var providers: [ProviderUsage]
    var lastUpdated: Date?

    static let empty = UsageSnapshot(providers: [], lastUpdated: nil)
}

enum UsageFormat {
    static func usd(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = value >= 100 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    static func tokens(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        if count >= 1_000_000 {
            let millions = Double(count) / 1_000_000
            return (formatter.string(from: NSNumber(value: millions)) ?? "\(millions)") + "M tok"
        }
        if count >= 1_000 {
            let thousands = Double(count) / 1_000
            return (formatter.string(from: NSNumber(value: thousands)) ?? "\(thousands)") + "k tok"
        }
        return "\(count) tok"
    }

    static func countdown(to date: Date) -> String {
        let remaining = date.timeIntervalSinceNow
        if remaining <= 0 { return "Reset due" }
        let days = Int(remaining) / 86_400
        let hours = (Int(remaining) % 86_400) / 3_600
        if days > 0 { return "Resets in \(days)d \(hours)h" }
        let minutes = (Int(remaining) % 3_600) / 60
        if hours > 0 { return "Resets in \(hours)h \(minutes)m" }
        return "Resets in \(max(minutes, 1))m"
    }

    static func monthStart(now: Date = Date()) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
    }

    static func nextMonth(after date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart(now: date)) ?? date
    }
}
