import Foundation

enum UsageSampler {
    static func sample(preferences: UsagePreferencesSnapshot) -> UsageSnapshot {
        var providers: [ProviderUsage] = []
        if preferences.cursorEnabled {
            providers.append(CursorUsageClient.fetch())
        }
        if preferences.grokBotEnabled {
            providers.append(GrokBotUsageClient.fetch())
        }
        if preferences.openaiEnabled {
            let openAIKey = preferences.openaiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            var openAI: ProviderUsage? = openAIKey.isEmpty
                ? nil
                : OpenAIUsageClient.fetch(apiKey: openAIKey, monthlyBudget: preferences.openaiMonthlyBudget)
            if preferences.openaiPlanLimitsEnabled, let limits = CodexLimitsClient.fetch() {
                var block = openAI ?? ProviderUsage(
                    id: "openai",
                    title: "OpenAI",
                    subtitle: "ChatGPT plan",
                    detail: "",
                    percent: nil,
                    resetLabel: "",
                    error: nil
                )
                block.limitBars = CodexLimitsClient.bars(limits)
                var note = ["ChatGPT \(limits.planType ?? "plan") · Codex limits"]
                if limits.source == .sessionLog {
                    note.append("from Codex log · updated \(limits.observedAt.formatted(date: .omitted, time: .shortened))")
                }
                block.limitsNote = note.joined(separator: " · ")
                openAI = block
            }
            if let openAI { providers.append(openAI) }
        }
        if preferences.anthropicEnabled {
            let anthropicKey = preferences.anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !anthropicKey.isEmpty {
                providers.append(AnthropicUsageClient.fetch(apiKey: anthropicKey))
            }
        }
        return UsageSnapshot(providers: providers, lastUpdated: Date())
    }
}

struct UsagePreferencesSnapshot: Sendable {
    var cursorEnabled: Bool
    var grokBotEnabled: Bool
    var openaiEnabled: Bool
    var anthropicEnabled: Bool
    var openaiKey: String
    var anthropicKey: String
    var openaiMonthlyBudget: Double
    var openaiPlanLimitsEnabled: Bool = true
}
