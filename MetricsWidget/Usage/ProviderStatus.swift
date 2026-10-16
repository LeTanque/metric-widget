import Foundation

/// Overall service health for one provider, mapped from its public status page.
enum StatusLevel: String, Sendable {
    case operational
    case degraded
    case outage
    case critical
    case unavailable

    var dot: String {
        switch self {
        case .operational: "🟢"
        case .degraded: "🌕"
        case .outage: "🟠"
        case .critical: "🔴"
        case .unavailable: "\u{26AA}\u{FE0F}"
        }
    }

    /// Hourly when green, 30 min when degraded, 15 min for outages or unreachable pages.
    var pollInterval: TimeInterval {
        switch self {
        case .operational: 60 * 60
        case .degraded: 30 * 60
        case .outage, .critical, .unavailable: 15 * 60
        }
    }
}

enum StatusProvider: String, CaseIterable, Sendable {
    case cursor
    case grokBot = "grokbot"
    case openai
    case claude

    var displayName: String {
        switch self {
        case .cursor: "Cursor"
        case .grokBot: "Grok Bot"
        case .openai: "OpenAI"
        case .claude: "Claude"
        }
    }

    var endpoint: URL {
        switch self {
        case .cursor: URL(string: "https://status.cursor.com/api/v2/summary.json")!
        case .grokBot: URL(string: "https://status.x.ai/feed.xml")!
        case .openai: URL(string: "https://status.openai.com/api/v2/summary.json")!
        case .claude: URL(string: "https://status.claude.com/api/v2/summary.json")!
        }
    }

    var feedFormat: StatusFeedFormat {
        self == .grokBot ? .incidentRSS : .statuspage
    }

    /// Same UserDefaults keys and defaults as the Usage provider toggles.
    var isUsageEnabled: Bool {
        let defaults = UserDefaults.standard
        switch self {
        case .cursor: return defaults.object(forKey: "usage.cursor.enabled") as? Bool ?? true
        case .grokBot: return defaults.object(forKey: "usage.grokbot.enabled") as? Bool ?? true
        case .openai: return defaults.object(forKey: "usage.openai.enabled") as? Bool ?? true
        case .claude: return defaults.object(forKey: "usage.anthropic.enabled") as? Bool ?? false
        }
    }
}

enum StatusFeedFormat: Sendable {
    case statuspage
    case incidentRSS
}

struct ProviderStatusReading: Sendable, Equatable {
    var level: StatusLevel
    /// One-line description for non-green levels.
    var summary: String?

    static let unavailable = ProviderStatusReading(level: .unavailable, summary: nil)
}

enum ProviderStatusClient {
    static func fetch(_ provider: StatusProvider) -> ProviderStatusReading {
        fetch(url: provider.endpoint, format: provider.feedFormat)
    }

    /// Any transport error, non-2xx status, or unreadable body is reported as unavailable.
    static func fetch(url: URL, format: StatusFeedFormat, now: Date = Date()) -> ProviderStatusReading {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try URLSession.shared.synchronousData(for: request)
        } catch {
            return .unavailable
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return .unavailable
        }
        switch format {
        case .statuspage: return parseStatuspage(data) ?? .unavailable
        case .incidentRSS: return parseIncidentRSS(data, now: now) ?? .unavailable
        }
    }

    // MARK: Statuspage (`/api/v2/summary.json`)

    private struct StatuspageSummary: Decodable {
        struct Status: Decodable {
            let indicator: String?
            let description: String?
        }
        struct Incident: Decodable {
            let name: String?
            let status: String?
        }
        let status: Status
        let incidents: [Incident]?
    }

    static func parseStatuspage(_ data: Data) -> ProviderStatusReading? {
        guard let summary = try? JSONDecoder().decode(StatuspageSummary.self, from: data) else { return nil }
        let level = level(forIndicator: summary.status.indicator)
        guard level != .operational else { return ProviderStatusReading(level: .operational, summary: nil) }
        let closed: Set<String> = ["resolved", "postmortem", "completed"]
        let incident = summary.incidents?.first {
            !closed.contains(($0.status ?? "").lowercased()) && !($0.name ?? "").isEmpty
        }
        let text = incident?.name ?? summary.status.description ?? "Service issues reported"
        return ProviderStatusReading(level: level, summary: oneLine(text))
    }

    /// Statuspage `status.indicator`: none → 🟢, minor/maintenance → 🌕, major → 🟠, critical → 🔴.
    static func level(forIndicator indicator: String?) -> StatusLevel {
        switch (indicator ?? "").lowercased() {
        case "none": .operational
        case "major": .outage
        case "critical": .critical
        default: .degraded
        }
    }

    // MARK: status.x.ai incident RSS (`/feed.xml`)

    /// Unresolved incidents newer than this count as active; older open items are treated as stale.
    static let activeIncidentWindow: TimeInterval = 7 * 24 * 60 * 60

    static func parseIncidentRSS(_ data: Data, now: Date) -> ProviderStatusReading? {
        let collector = RSSItemCollector()
        let parser = XMLParser(data: data)
        parser.delegate = collector
        guard parser.parse(), collector.sawChannel else { return nil }

        var worst: (level: StatusLevel, title: String)?
        for item in collector.items {
            let categories = Set(item.categories.map { $0.lowercased() })
            if categories.contains("resolved") || categories.contains("completed") { continue }
            if let published = item.published, now.timeIntervalSince(published) > activeIncidentWindow { continue }
            let level = level(forSeverities: categories)
            if worst == nil || rank(level) > rank(worst!.level) {
                worst = (level, item.title)
            }
        }
        guard let worst else { return ProviderStatusReading(level: .operational, summary: nil) }
        return ProviderStatusReading(level: worst.level, summary: oneLine(stripComponentPrefix(worst.title)))
    }

    /// x.ai severities: outage → 🟠, disruption/degraded/maintenance/other → 🌕, critical/major outage → 🔴.
    static func level(forSeverities categories: Set<String>) -> StatusLevel {
        if categories.contains("critical") || categories.contains("major_outage") || categories.contains("major outage") {
            return .critical
        }
        if categories.contains("outage") || categories.contains("partial_outage") || categories.contains("partial outage") {
            return .outage
        }
        return .degraded
    }

    private static func rank(_ level: StatusLevel) -> Int {
        switch level {
        case .operational, .unavailable: 0
        case .degraded: 1
        case .outage: 2
        case .critical: 3
        }
    }

    private static func stripComponentPrefix(_ title: String) -> String {
        guard title.hasPrefix("["), let close = title.firstIndex(of: "]") else { return title }
        let rest = title[title.index(after: close)...].trimmingCharacters(in: .whitespaces)
        return rest.isEmpty ? title : rest
    }

    /// Max description length so "GROK BOT ⚪️ <text>" fits one line of the 320 pt Usage tile
    /// (PressStart2P at 6 pt is ~6 pt per glyph).
    static let descriptionLimit = 36

    /// Collapses whitespace and truncates at a word boundary with a single "…" (U+2026).
    static func oneLine(_ text: String, limit: Int = descriptionLimit) -> String {
        let collapsed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard collapsed.count > limit else { return collapsed }
        var cut = String(collapsed.prefix(limit - 1))
        if let space = cut.lastIndex(of: " "), cut.distance(from: cut.startIndex, to: space) >= limit / 2 {
            cut = String(cut[..<space])
        }
        return cut.trimmingCharacters(in: CharacterSet(charactersIn: " ,.;:-–—")) + "\u{2026}"
    }
}

private final class RSSItemCollector: NSObject, XMLParserDelegate {
    struct Item {
        var title = ""
        var categories: [String] = []
        var published: Date?
    }

    private(set) var items: [Item] = []
    private(set) var sawChannel = false
    private var current: Item?
    private var text = ""

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "channel" { sawChannel = true }
        if elementName == "item" { current = Item() }
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "title": current?.title = value
        case "category": current?.categories.append(value)
        case "pubDate": current?.published = Self.dateFormatter.date(from: value)
        case "item":
            if let current { items.append(current) }
            current = nil
        default: break
        }
        text = ""
    }
}

/// Green phrase picked per provider: once a day, and again on any change back to green.
enum GreenPhrase {
    static let all = ["All systems go!", "Ready to rock!", "LFG!", "Can't stop, won't stop!"]

    struct Pick: Equatable, Sendable {
        var phrase: String
        var day: String
    }

    /// Returns the phrase pick to show (and persist) for a green reading.
    /// `previous` is the last persisted level for the provider (nil if never seen).
    static func resolve(
        previous: StatusLevel?,
        stored: Pick?,
        today: String,
        choose: () -> String = { all.randomElement()! }
    ) -> Pick {
        let changedBackToGreen = previous != nil && previous != .operational
        if let stored, stored.day == today, all.contains(stored.phrase), !changedBackToGreen {
            return stored
        }
        return Pick(phrase: choose(), day: today)
    }

    static func dayKey(_ date: Date = Date(), calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
