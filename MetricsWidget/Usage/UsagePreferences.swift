import Foundation
import Observation

struct UsageSaveResult {
    var message: String
    var isError: Bool
}

@Observable
@MainActor
final class UsagePreferences {
    var cursorEnabled: Bool
    var openaiEnabled: Bool
    var anthropicEnabled: Bool
    var openaiKey: String
    var anthropicKey: String

    init() {
        let defaults = UserDefaults.standard
        cursorEnabled = defaults.object(forKey: Keys.cursor) as? Bool ?? true
        openaiEnabled = defaults.object(forKey: Keys.openai) as? Bool ?? true
        anthropicEnabled = defaults.object(forKey: Keys.anthropic) as? Bool ?? false
        openaiKey = ""
        anthropicKey = ""
        reload()
    }

    func reload() {
        let defaults = UserDefaults.standard
        cursorEnabled = defaults.object(forKey: Keys.cursor) as? Bool ?? true
        openaiEnabled = defaults.object(forKey: Keys.openai) as? Bool ?? true
        anthropicEnabled = defaults.object(forKey: Keys.anthropic) as? Bool ?? false
        openaiKey = KeychainStore.password(account: KeychainAccount.openAI) ?? ""
        anthropicKey = KeychainStore.password(account: KeychainAccount.anthropic) ?? ""
    }

    func save() -> UsageSaveResult {
        UserDefaults.standard.set(cursorEnabled, forKey: Keys.cursor)
        UserDefaults.standard.set(openaiEnabled, forKey: Keys.openai)
        UserDefaults.standard.set(anthropicEnabled, forKey: Keys.anthropic)

        let openAIToStore = openaiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let anthropicToStore = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if !openAIToStore.isEmpty, !KeychainStore.setPassword(openAIToStore, account: KeychainAccount.openAI) {
            return UsageSaveResult(message: "Couldn’t save the OpenAI key to Keychain.", isError: true)
        }

        if !anthropicToStore.isEmpty, !KeychainStore.setPassword(anthropicToStore, account: KeychainAccount.anthropic) {
            return UsageSaveResult(message: "Couldn’t save the Anthropic key to Keychain.", isError: true)
        }

        reload()

        var parts: [String] = ["Settings saved."]
        if KeychainStore.hasPassword(account: KeychainAccount.openAI) {
            parts.append("OpenAI key stored.")
        }
        if KeychainStore.hasPassword(account: KeychainAccount.anthropic) {
            parts.append("Anthropic key stored.")
        }
        parts.append("Refreshing usage…")
        return UsageSaveResult(message: parts.joined(separator: " "), isError: false)
    }

    private enum Keys {
        static let cursor = "usage.cursor.enabled"
        static let openai = "usage.openai.enabled"
        static let anthropic = "usage.anthropic.enabled"
    }
}
