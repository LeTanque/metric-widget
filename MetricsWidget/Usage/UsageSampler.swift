import Foundation

enum UsageSampler {
    static func sample(preferences: UsagePreferencesSnapshot) -> UsageSnapshot {
        var providers: [ProviderUsage] = []
        if preferences.cursorEnabled {
            providers.append(CursorUsageClient.fetch())
        }
        if preferences.openaiEnabled {
            providers.append(OpenAIUsageClient.fetch(apiKey: preferences.openaiKey))
        }
        if preferences.anthropicEnabled {
            providers.append(AnthropicUsageClient.fetch(apiKey: preferences.anthropicKey))
        }
        return UsageSnapshot(providers: providers, lastUpdated: Date())
    }
}

struct UsagePreferencesSnapshot: Sendable {
    var cursorEnabled: Bool
    var openaiEnabled: Bool
    var anthropicEnabled: Bool
    var openaiKey: String
    var anthropicKey: String
}
