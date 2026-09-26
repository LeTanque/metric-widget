import Foundation

enum GrokBotUsageClient {
    static func fetch() -> ProviderUsage {
        guard let token = CursorStateDatabase.value(forKey: "cursorAuth/accessToken"), !token.isEmpty else {
            return .placeholder(
                id: "grokbot",
                title: "Grok Bot",
                message: "Sign in to the Cursor app on this Mac"
            )
        }

        var request = URLRequest(
            url: URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetSandUsageStatus")!
        )
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.httpBody = Data("{}".utf8)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try URLSession.shared.synchronousData(for: request)
        } catch {
            return errorUsage("Couldn’t reach Grok Bot usage")
        }

        guard let http = response as? HTTPURLResponse else {
            return errorUsage("Couldn’t reach Grok Bot usage")
        }
        if http.statusCode == 401 {
            return errorUsage("Session expired — sign in to Cursor again")
        }
        guard (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return errorUsage("Grok Bot usage API changed or failed (\(http.statusCode))")
        }

        if json["hasNonZeroIncludedLimit"] as? Bool == false {
            return .placeholder(
                id: "grokbot",
                title: "Grok Bot",
                message: "No Grok Bot allowance on this account"
            )
        }

        let usedPercent = number(json["usagePercent"]) ?? 0
        let remainingPercent = min(100, max(0, 100 - usedPercent))
        let usedRounded = Int(usedPercent.rounded())
        let leftRounded = Int(remainingPercent.rounded())
        let detail = "\(usedRounded)% used · \(leftRounded)% left this week"

        let cursorPlan = json["cursorPlanName"] as? String ?? ""
        let grokPlan = json["grokPlanLabel"] as? String ?? ""
        var subtitleParts: [String] = []
        if !grokPlan.isEmpty { subtitleParts.append(grokPlan) }
        if !cursorPlan.isEmpty { subtitleParts.append(cursorPlan) }
        subtitleParts.append("weekly")
        let subtitle = subtitleParts.joined(separator: " · ")

        let reset = parseDashboardDate(json["nextResetTimestampUtc"])
        let resetLabel = reset.map(UsageFormat.countdown(to:)) ?? "Reset unknown"

        return ProviderUsage(
            id: "grokbot",
            title: "Grok Bot",
            subtitle: subtitle,
            detail: detail,
            percent: remainingPercent,
            resetLabel: resetLabel,
            error: nil
        )
    }

    private static func errorUsage(_ message: String) -> ProviderUsage {
        ProviderUsage(
            id: "grokbot",
            title: "Grok Bot",
            subtitle: "Unofficial session · weekly",
            detail: "—",
            percent: nil,
            resetLabel: "",
            error: message
        )
    }

    private static func number(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let s = value as? String { return Double(s) }
        return nil
    }

    private static func parseDashboardDate(_ value: Any?) -> Date? {
        if let s = value as? String {
            if let n = Double(s) {
                return Date(timeIntervalSince1970: n > 1e12 ? n / 1000 : n)
            }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: s) { return date }
            iso.formatOptions = [.withInternetDateTime]
            return iso.date(from: s)
        }
        if let n = number(value) {
            return Date(timeIntervalSince1970: n > 1e12 ? n / 1000 : n)
        }
        return nil
    }
}
