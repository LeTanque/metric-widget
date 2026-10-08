import Foundation

enum OpenAIUsageClient {
    static func fetch(apiKey: String, monthlyBudget: Double) -> ProviderUsage {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .placeholder(id: "openai", title: "OpenAI", message: "Add an Admin key in Settings")
        }

        let start = Int(UsageFormat.monthStart().timeIntervalSince1970)
        var components = URLComponents(string: "https://api.openai.com/v1/organization/costs")!
        components.queryItems = [
            URLQueryItem(name: "start_time", value: String(start)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: "31")
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        request.setValue("Bearer \(trimmed)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try URLSession.shared.synchronousData(for: request)
        } catch {
            return errorUsage("Couldn’t reach OpenAI")
        }

        guard let http = response as? HTTPURLResponse else {
            return errorUsage("Couldn’t reach OpenAI")
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            return errorUsage("Need an Admin key with api.usage.read")
        }
        guard (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let buckets = json["data"] as? [[String: Any]] else {
            return errorUsage("OpenAI usage request failed (\(http.statusCode))")
        }

        var total = 0.0
        for bucket in buckets {
            guard let results = bucket["results"] as? [[String: Any]] else { continue }
            for row in results {
                if let amount = row["amount"] as? [String: Any], let value = amount["value"] as? Double {
                    total += value
                } else if let amount = row["amount"] as? [String: Any], let value = amount["value"] as? NSNumber {
                    total += value.doubleValue
                }
            }
        }

        let reset = UsageFormat.nextMonth()
        let hasBudget = monthlyBudget > 0
        let remainingPercent = hasBudget
            ? min(100, max(0, (monthlyBudget - total) / monthlyBudget * 100))
            : nil
        let detail: String
        if let remainingPercent {
            let left = Int(remainingPercent.rounded())
            detail = "\(UsageFormat.usd(total)) of \(UsageFormat.usd(monthlyBudget)) used · \(left)% left this month"
        } else {
            detail = "\(UsageFormat.usd(total)) this month"
        }
        return ProviderUsage(
            id: "openai",
            title: "OpenAI",
            subtitle: "Calendar month · org costs",
            detail: detail,
            percent: remainingPercent,
            resetLabel: UsageFormat.countdown(to: reset),
            error: nil,
            footnote: hasBudget ? nil : "Set a monthly budget in Settings to show a bar",
            meterTitle: hasBudget ? "Budget remaining" : nil
        )
    }

    private static func errorUsage(_ message: String) -> ProviderUsage {
        ProviderUsage(
            id: "openai",
            title: "OpenAI",
            subtitle: "Calendar month",
            detail: "—",
            percent: nil,
            resetLabel: "",
            error: message
        )
    }
}
