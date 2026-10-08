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
    var grokBotEnabled: Bool
    var openaiEnabled: Bool
    var anthropicEnabled: Bool
    var openaiKey: String
    var anthropicKey: String
    var openaiMonthlyBudget: String

    init() {
        IdentityMigration.runIfNeeded()
        let defaults = UserDefaults.standard
        cursorEnabled = defaults.object(forKey: Keys.cursor) as? Bool ?? true
        grokBotEnabled = defaults.object(forKey: Keys.grokBot) as? Bool ?? true
        openaiEnabled = defaults.object(forKey: Keys.openai) as? Bool ?? true
        anthropicEnabled = defaults.object(forKey: Keys.anthropic) as? Bool ?? false
        openaiKey = ""
        anthropicKey = ""
        openaiMonthlyBudget = ""
        reload()
    }

    func reload() {
        let defaults = UserDefaults.standard
        cursorEnabled = defaults.object(forKey: Keys.cursor) as? Bool ?? true
        grokBotEnabled = defaults.object(forKey: Keys.grokBot) as? Bool ?? true
        openaiEnabled = defaults.object(forKey: Keys.openai) as? Bool ?? true
        anthropicEnabled = defaults.object(forKey: Keys.anthropic) as? Bool ?? false
        openaiKey = KeychainStore.password(account: KeychainAccount.openAI) ?? ""
        anthropicKey = KeychainStore.password(account: KeychainAccount.anthropic) ?? ""
        openaiMonthlyBudget = Self.displayMonthlyBudget(defaults.double(forKey: Keys.openaiBudget))
    }

    var openaiMonthlyBudgetValue: Double {
        Self.parseMonthlyBudget(openaiMonthlyBudget)
    }

    func save() -> UsageSaveResult {
        UserDefaults.standard.set(cursorEnabled, forKey: Keys.cursor)
        UserDefaults.standard.set(grokBotEnabled, forKey: Keys.grokBot)
        UserDefaults.standard.set(openaiEnabled, forKey: Keys.openai)
        UserDefaults.standard.set(anthropicEnabled, forKey: Keys.anthropic)
        let budget = openaiMonthlyBudgetValue
        if budget > 0 {
            UserDefaults.standard.set(budget, forKey: Keys.openaiBudget)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.openaiBudget)
        }

        let openAIToStore = openaiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let anthropicToStore = anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)

        if !KeychainStore.setPassword(openAIToStore.isEmpty ? nil : openAIToStore, account: KeychainAccount.openAI) {
            return UsageSaveResult(message: "Couldn’t save the OpenAI key.", isError: true)
        }

        if !KeychainStore.setPassword(anthropicToStore.isEmpty ? nil : anthropicToStore, account: KeychainAccount.anthropic) {
            return UsageSaveResult(message: "Couldn’t save the Anthropic key.", isError: true)
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

    func clearOpenAIKey() {
        openaiKey = ""
        _ = KeychainStore.setPassword(nil, account: KeychainAccount.openAI)
    }

    func clearAnthropicKey() {
        anthropicKey = ""
        _ = KeychainStore.setPassword(nil, account: KeychainAccount.anthropic)
    }

    private enum Keys {
        static let cursor = "usage.cursor.enabled"
        static let grokBot = "usage.grokbot.enabled"
        static let openai = "usage.openai.enabled"
        static let anthropic = "usage.anthropic.enabled"
        static let openaiBudget = "usage.openai.monthlyBudget"
    }

    private static func parseMonthlyBudget(_ raw: String) -> Double {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("$") {
            text.removeFirst()
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        text = text.replacingOccurrences(of: ",", with: "")
        return Double(text) ?? 0
    }

    private static func displayMonthlyBudget(_ value: Double) -> String {
        guard value > 0 else { return "" }
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
