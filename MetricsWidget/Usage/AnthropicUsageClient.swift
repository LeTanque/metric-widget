import Foundation

enum AnthropicUsageClient {
    static func fetch(apiKey: String) -> ProviderUsage {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .placeholder(id: "anthropic", title: "Anthropic", message: "Add an Admin key in Settings")
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        let start = iso.string(from: UsageFormat.monthStart())
        let end = iso.string(from: Date().addingTimeInterval(3600))

        var components = URLComponents(string: "https://api.anthropic.com/v1/organizations/usage_report/messages")!
        components.queryItems = [
            URLQueryItem(name: "starting_at", value: start),
            URLQueryItem(name: "ending_at", value: end),
            URLQueryItem(name: "bucket_width", value: "1d")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        request.setValue(trimmed, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try URLSession.shared.synchronousData(for: request)
        } catch {
            return errorUsage("Couldn’t reach Anthropic")
        }

        guard let http = response as? HTTPURLResponse else {
            return errorUsage("Couldn’t reach Anthropic")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            return errorUsage("Need an Admin key (sk-ant-admin…)")
        }
        guard (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let buckets = json["data"] as? [[String: Any]] else {
            return errorUsage("Anthropic usage request failed (\(http.statusCode))")
        }

        var input = 0
        var output = 0
        for bucket in buckets {
            guard let results = bucket["results"] as? [[String: Any]] else { continue }
            for row in results {
                input += intValue(row["uncached_input_tokens"]) + intValue(row["input_tokens"])
                output += intValue(row["output_tokens"])
                if let cache = row["cache_creation"] as? [String: Any] {
                    input += intValue(cache["ephemeral_1h_input_tokens"])
                    input += intValue(cache["ephemeral_5m_input_tokens"])
                }
                input += intValue(row["cache_read_input_tokens"])
            }
        }

        let reset = UsageFormat.nextMonth()
        return ProviderUsage(
            id: "anthropic",
            title: "Anthropic",
            subtitle: "Calendar month · messages",
            detail: "\(UsageFormat.tokens(input + output)) this month",
            percent: nil,
            resetLabel: UsageFormat.countdown(to: reset),
            error: nil
        )
    }

    private static func intValue(_ value: Any?) -> Int {
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        if let n = value as? Double { return Int(n) }
        return 0
    }

    private static func errorUsage(_ message: String) -> ProviderUsage {
        ProviderUsage(
            id: "anthropic",
            title: "Anthropic",
            subtitle: "Calendar month",
            detail: "—",
            percent: nil,
            resetLabel: "",
            error: message
        )
    }
}
