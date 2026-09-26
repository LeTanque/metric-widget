import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: UsagePreferences
    var usagePanelVisible: Bool
    var onSave: () -> Void

    @State private var saveStatus: UsageSaveResult?

    var body: some View {
        Form {
            Section("Providers") {
                Toggle("Cursor (signed-in app session)", isOn: $preferences.cursorEnabled)
                Toggle("Grok Bot (weekly included quota)", isOn: $preferences.grokBotEnabled)
                Toggle("OpenAI", isOn: $preferences.openaiEnabled)
                Toggle("Anthropic", isOn: $preferences.anthropicEnabled)
            }

            Section("Keys") {
                SecureField("OpenAI Admin API key", text: $preferences.openaiKey)
                if KeychainStore.hasPassword(account: KeychainAccount.openAI), preferences.openaiKey.isEmpty {
                    Text("OpenAI key is saved in Keychain. Paste again only to replace it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Needs an Admin key with api.usage.read (not a regular project key). Stored as \(KeychainStore.service) / \(KeychainAccount.openAI).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Anthropic Admin API key", text: $preferences.anthropicKey)
                if KeychainStore.hasPassword(account: KeychainAccount.anthropic), preferences.anthropicKey.isEmpty {
                    Text("Anthropic key is saved in Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("sk-ant-admin… Stored as \(KeychainAccount.anthropic).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Save") {
                    let result = preferences.save()
                    saveStatus = result
                    if !result.isError {
                        onSave()
                    }
                }
                .keyboardShortcut(.defaultAction)

                if let saveStatus {
                    Text(saveStatus.message)
                        .font(.caption)
                        .foregroundStyle(saveStatus.isError ? .red : .green)
                }

                if !usagePanelVisible {
                    Text("Turn on Usage or All in one in the menu bar to see metrics on the desktop.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Cursor and Grok Bot usage are unofficial: this app reads the local Cursor session and calls the same dashboard endpoints the website uses (monthly plan meter for Cursor, weekly Sand pool for Grok Bot). Grok Bot’s weekly allowance is separate from Cursor’s monthly included bar; after weekly Grok runs out, spill may use Cursor on-demand. These calls can break when Cursor changes the API. Keys never leave the Keychain except to OpenAI and Anthropic.")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 420)
        .padding()
    }
}
