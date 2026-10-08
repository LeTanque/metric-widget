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
            if !openAIKey.isEmpty {
                providers.append(OpenAIUsageClient.fetch(apiKey: openAIKey, monthlyBudget: preferences.openaiMonthlyBudget))
            }
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
}
