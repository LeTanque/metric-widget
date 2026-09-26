import Foundation

enum CursorUsageClient {
    static func fetch() -> ProviderUsage {
        guard let token = CursorStateDatabase.value(forKey: "cursorAuth/accessToken"), !token.isEmpty else {
            return .placeholder(
                id: "cursor",
                title: "Cursor",
                message: "Sign in to the Cursor app on this Mac"
            )
        }

        let email = CursorStateDatabase.value(forKey: "cursorAuth/cachedEmail") ?? ""
        let plan = (CursorStateDatabase.value(forKey: "cursorAuth/stripeMembershipType") ?? "plan").capitalized

        var request = URLRequest(
            url: URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage")!
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
            return errorUsage("Couldn’t reach Cursor")
        }

        guard let http = response as? HTTPURLResponse else {
            return errorUsage("Couldn’t reach Cursor")
        }
        if http.statusCode == 401 {
            return errorUsage("Session expired — sign in to Cursor again")
        }
        guard (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return errorUsage("Cursor usage API changed or failed (\(http.statusCode))")
        }

        let planUsage = json["planUsage"] as? [String: Any] ?? [:]
        let included = cents(planUsage["includedSpend"])
        let extraSpend = cents(planUsage["bonusSpend"])
        let total = cents(planUsage["totalSpend"]) ?? ((included ?? 0) + (extraSpend ?? 0))
        let limit = cents(planUsage["limit"])
        let remaining = cents(planUsage["remaining"])

        var percent: Double?
        var remainingIncluded: Double?
        if let limit, limit > 0 {
            let left = includedRemaining(
                limit: limit,
                includedSpend: included,
                apiRemaining: remaining
            )
            remainingIncluded = left
            percent = min(100, max(0, left / limit * 100))
        } else if let raw = number(planUsage["totalPercentUsed"]) {
            let used = raw > 1.5 ? raw : raw * 100
            percent = min(100, max(0, 100 - used))
        }

        var detail: String
        if let limit, limit > 0, let left = remainingIncluded {
            let used = included ?? max(0, limit - left)
            detail = "\(UsageFormat.usd(used)) / \(UsageFormat.usd(limit)) · \(UsageFormat.usd(left)) left"
        } else {
            detail = UsageFormat.usd(included ?? total)
            if let remaining {
                detail += " · \(UsageFormat.usd(remaining)) left"
            }
        }
        if let extraSpend, extraSpend > 0 {
            detail += " · +\(UsageFormat.usd(extraSpend)) beyond included"
        }

        let reset = parseCursorDate(json["billingCycleEnd"])
        let resetLabel = reset.map(UsageFormat.countdown(to:)) ?? "Reset unknown"
        let subtitle = [plan, email.isEmpty ? nil : email].compactMap { $0 }.joined(separator: " · ")

        return ProviderUsage(
            id: "cursor",
            title: "Cursor",
            subtitle: subtitle.isEmpty ? "Current period" : subtitle,
            detail: detail,
            percent: percent,
            resetLabel: resetLabel,
            error: nil
        )
    }

    private static func errorUsage(_ message: String) -> ProviderUsage {
        ProviderUsage(
            id: "cursor",
            title: "Cursor",
            subtitle: "Unofficial session",
            detail: "—",
            percent: nil,
            resetLabel: "",
            error: message
        )
    }

    /// Included quota still available this period (USD). Prefers API `remaining` when it matches limit − used.
    private static func includedRemaining(
        limit: Double,
        includedSpend: Double?,
        apiRemaining: Double?
    ) -> Double {
        let fromIncluded = max(0, limit - (includedSpend ?? 0))
        guard let apiRemaining else { return fromIncluded }
        let tolerance = 0.02
        if abs(apiRemaining - fromIncluded) <= tolerance {
            return min(limit, max(0, apiRemaining))
        }
        if includedSpend == nil, apiRemaining >= 0, apiRemaining <= limit {
            return apiRemaining
        }
        return fromIncluded
    }

    private static func cents(_ value: Any?) -> Double? {
        guard let number = number(value) else { return nil }
        return number / 100.0
    }

    private static func number(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let s = value as? String { return Double(s) }
        return nil
    }

    private static func parseCursorDate(_ value: Any?) -> Date? {
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

extension URLSession {
    func synchronousData(for request: URLRequest) throws -> (Data, URLResponse) {
        let box = DataResponseBox()
        let semaphore = DispatchSemaphore(value: 0)
        let task = dataTask(with: request) { data, response, error in
            if let error {
                box.result = .failure(error)
            } else if let data, let response {
                box.result = .success((data, response))
            } else {
                box.result = .failure(URLError(.badServerResponse))
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        switch box.result {
        case .success(let pair): return pair
        case .failure(let error): throw error
        case nil: throw URLError(.timedOut)
        }
    }
}

private final class DataResponseBox: @unchecked Sendable {
    var result: Result<(Data, URLResponse), Error>?
}
