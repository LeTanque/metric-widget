import Foundation
import SQLite3

enum CursorUsageClient {
    static func fetch() -> ProviderUsage {
        guard let token = stateValue("cursorAuth/accessToken"), !token.isEmpty else {
            return .placeholder(
                id: "cursor",
                title: "Cursor",
                message: "Sign in to the Cursor app on this Mac"
            )
        }

        let email = stateValue("cursorAuth/cachedEmail") ?? ""
        let plan = (stateValue("cursorAuth/stripeMembershipType") ?? "plan").capitalized

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
        let bonus = cents(planUsage["bonusSpend"])
        let total = cents(planUsage["totalSpend"]) ?? ((included ?? 0) + (bonus ?? 0))
        let limit = cents(planUsage["limit"])
        let remaining = cents(planUsage["remaining"])

        var percent: Double?
        if let limit, limit > 0, let included {
            percent = min(100, included / limit * 100)
        } else if let raw = number(planUsage["totalPercentUsed"]) {
            percent = raw > 1.5 ? raw : raw * 100
        }

        var detail = UsageFormat.usd(included ?? total)
        if let limit, limit > 0 {
            detail += " / \(UsageFormat.usd(limit))"
        } else if let remaining {
            detail += " · \(UsageFormat.usd(remaining)) left"
        }
        if let bonus, bonus > 0 {
            detail += " · +\(UsageFormat.usd(bonus)) bonus"
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

    private static func stateValue(_ key: String) -> String? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Cursor/User/globalStorage/state.vscdb")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("metricswidget-cursor", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let copy = tempDir.appendingPathComponent("state.vscdb")
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            let dest = URL(fileURLWithPath: copy.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            try? fm.removeItem(at: dest)
            try? fm.copyItem(at: source, to: dest)
        }

        let dbURL = fm.fileExists(atPath: copy.path) ? copy : url
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        guard sqlite3_open_v2(dbURL.path, &db, flags, nil) == SQLITE_OK, db != nil else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }

        let escaped = key.replacingOccurrences(of: "'", with: "''")
        for table in ["ItemTable", "cursorDiskKV"] {
            let sql = "SELECT value FROM \(table) WHERE key = '\(escaped)' LIMIT 1"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { continue }
            defer { sqlite3_finalize(statement) }
            guard sqlite3_step(statement) == SQLITE_ROW else { continue }
            if let pointer = sqlite3_column_text(statement, 0) {
                let value = String(cString: pointer)
                if !value.isEmpty { return value }
            }
        }
        return nil
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
