import Foundation

/// ChatGPT-plan Codex rate limits (5-hour + weekly), as shown by Codex `/status`.
/// Unofficial: tries the ChatGPT usage endpoint with Codex's stored login (read-only; never
/// refreshes or writes tokens), then falls back to the newest `rate_limits` event in
/// Codex session logs. Any failure returns nil so the tile just hides the bars.
struct CodexLimits: Sendable, Hashable {
    struct Window: Sendable, Hashable {
        var usedPercent: Double
        var windowMinutes: Int
        var resetsAt: Date?
    }

    enum Source: Sendable, Hashable { case live, sessionLog }

    var primary: Window?
    var secondary: Window?
    var planType: String?
    var observedAt: Date
    var source: Source
}

enum CodexLimitsClient {
    static func fetch(now: Date = Date()) -> CodexLimits? {
        live(now: now) ?? sessionLog()
    }

    static var codexHome: URL {
        if let env = ProcessInfo.processInfo.environment["CODEX_HOME"], !env.isEmpty {
            return URL(fileURLWithPath: env, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
    }

    // MARK: Live endpoint

    private struct Auth: Decodable {
        struct Tokens: Decodable {
            let access_token: String?
            let account_id: String?
        }
        let tokens: Tokens?
    }

    private struct UsageResponse: Decodable {
        struct RateLimit: Decodable {
            struct Window: Decodable {
                let used_percent: Double?
                let limit_window_seconds: Int?
                let reset_at: Double?
            }
            let primary_window: Window?
            let secondary_window: Window?
        }
        let plan_type: String?
        let rate_limit: RateLimit?
    }

    private static func live(now: Date) -> CodexLimits? {
        let authURL = codexHome.appendingPathComponent("auth.json")
        guard let data = try? Data(contentsOf: authURL),
              let auth = try? JSONDecoder().decode(Auth.self, from: data),
              let token = auth.tokens?.access_token, !token.isEmpty else { return nil }

        var request = URLRequest(url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!)
        request.timeoutInterval = 15
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let account = auth.tokens?.account_id, !account.isEmpty {
            request.setValue(account, forHTTPHeaderField: "ChatGPT-Account-Id")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (body, response) = try? URLSession.shared.synchronousData(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(UsageResponse.self, from: body),
              let limits = decoded.rate_limit else { return nil }

        func window(_ w: UsageResponse.RateLimit.Window?) -> CodexLimits.Window? {
            guard let w, let used = w.used_percent else { return nil }
            return CodexLimits.Window(
                usedPercent: used,
                windowMinutes: (w.limit_window_seconds ?? 0) / 60,
                resetsAt: w.reset_at.map { Date(timeIntervalSince1970: $0) }
            )
        }
        let result = CodexLimits(
            primary: window(limits.primary_window),
            secondary: window(limits.secondary_window),
            planType: decoded.plan_type,
            observedAt: now,
            source: .live
        )
        return (result.primary == nil && result.secondary == nil) ? nil : result
    }

    // MARK: Session log fallback

    private static func sessionLog() -> CodexLimits? {
        let root = codexHome.appendingPathComponent("sessions", isDirectory: true)
        for file in newestSessionFiles(in: root, limit: 5) {
            if let limits = lastRateLimits(in: file) { return limits }
        }
        return nil
    }

    /// Newest rollout files, walking sessions/YYYY/MM/DD newest-first.
    private static func newestSessionFiles(in root: URL, limit: Int) -> [URL] {
        let fm = FileManager.default
        func sortedDirs(_ url: URL) -> [URL] {
            ((try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.hasDirectoryPath }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
        }
        var files: [URL] = []
        for year in sortedDirs(root) {
            for month in sortedDirs(year) {
                for day in sortedDirs(month) {
                    let items = ((try? fm.contentsOfDirectory(
                        at: day, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [])
                        .filter { $0.pathExtension == "jsonl" }
                    let dated = items.map { url -> (URL, Date) in
                        let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
                            .contentModificationDate ?? .distantPast
                        return (url, date)
                    }
                    files += dated.sorted { $0.1 > $1.1 }.map(\.0)
                    if files.count >= limit { return Array(files.prefix(limit)) }
                }
            }
        }
        return files
    }

    private static func lastRateLimits(in file: URL) -> CodexLimits? {
        guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let tail: UInt64 = 512 * 1024
        try? handle.seek(toOffset: size > tail ? size - tail : 0)
        guard let data = try? handle.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for line in text.split(separator: "\n").reversed() where line.contains("\"rate_limits\"") {
            guard let obj = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                  let limits = findRateLimits(obj) else { continue }
            func window(_ any: Any?) -> CodexLimits.Window? {
                guard let w = any as? [String: Any], let used = (w["used_percent"] as? NSNumber)?.doubleValue else { return nil }
                return CodexLimits.Window(
                    usedPercent: used,
                    windowMinutes: (w["window_minutes"] as? NSNumber)?.intValue ?? 0,
                    resetsAt: (w["resets_at"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue) }
                )
            }
            let primary = window(limits["primary"])
            let secondary = window(limits["secondary"])
            guard primary != nil || secondary != nil else { continue }
            let stamp = (obj["timestamp"] as? String).flatMap { iso.date(from: $0) }
                ?? ((try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date())
            return CodexLimits(
                primary: primary,
                secondary: secondary,
                planType: limits["plan_type"] as? String,
                observedAt: stamp,
                source: .sessionLog
            )
        }
        return nil
    }

    private static func findRateLimits(_ any: Any) -> [String: Any]? {
        if let dict = any as? [String: Any] {
            if let limits = dict["rate_limits"] as? [String: Any] { return limits }
            for value in dict.values {
                if let found = findRateLimits(value) { return found }
            }
        }
        return nil
    }

    // MARK: Bars

    /// Tile bars: percent remaining, with a "Resets in …" note. A window whose reset time has
    /// passed since a logged reading is shown as fully remaining.
    static func bars(_ limits: CodexLimits, now: Date = Date()) -> [UsageLimitBar] {
        [limits.primary, limits.secondary].compactMap { window in
            guard let window else { return nil }
            let elapsed = window.resetsAt.map { $0 <= now } ?? false
            let used = elapsed ? 0 : window.usedPercent
            return UsageLimitBar(
                title: title(minutes: window.windowMinutes),
                percentRemaining: min(max(100 - used, 0), 100),
                resetNote: window.resetsAt.map { elapsed ? "Reset since last reading" : UsageFormat.countdown(to: $0) } ?? ""
            )
        }
    }

    static func title(minutes: Int) -> String {
        switch minutes {
        case 10_080: return "Weekly limit"
        case let m where m > 0 && m % 60 == 0 && m < 1_440: return "\(m / 60)-hour limit"
        case let m where m > 0 && m % 1_440 == 0: return "\(m / 1_440)-day limit"
        default: return "Usage limit"
        }
    }
}
