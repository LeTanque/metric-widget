import SwiftUI

struct SettingsView: View {
    @Bindable var preferences: UsagePreferences
    @Bindable var clockPreferences: ClockPreferences
    var usagePanelVisible: Bool
    var clockPanelsVisible: Bool
    var onSave: () -> Void
    var onClockPreferencesChanged: () -> Void

    @State private var saveStatus: UsageSaveResult?

    var body: some View {
        Form {
            Section("World clocks") {
                Text("Each enabled zone gets its own desktop panel when **Clock** is on in the menu bar. Sizing is free-form (not limited to WidgetKit tiles).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ClockTimeZoneChoice.allCases) { zone in
                    Toggle(zone.menuTitle, isOn: clockBinding(for: zone))
                }
            }

            Section("Providers") {
                Toggle("Cursor (signed-in app session)", isOn: $preferences.cursorEnabled)
                Toggle("Grok Bot (weekly included quota)", isOn: $preferences.grokBotEnabled)
                Toggle("OpenAI", isOn: $preferences.openaiEnabled)
                Toggle("Anthropic", isOn: $preferences.anthropicEnabled)
            }

            Section("Keys") {
                TextField("OpenAI Admin API key", text: $preferences.openaiKey)
                    .onSubmit(saveKeys)
                Button("Clear") {
                    preferences.clearOpenAIKey()
                    onSave()
                }
                Text("Paste an Admin key with api.usage.read.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Anthropic Admin API key", text: $preferences.anthropicKey)
                    .onSubmit(saveKeys)
                Button("Clear") {
                    preferences.clearAnthropicKey()
                    onSave()
                }
                Text("Paste an Admin key (sk-ant-admin…).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Save") {
                    saveKeys()
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
                if !clockPanelsVisible {
                    Text("Turn on **Clock** in the menu bar to show enabled world-clock panels.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Cursor and Grok Bot usage are unofficial: this app reads the local Cursor session and calls the same dashboard endpoints the website uses (monthly plan meter for Cursor, weekly Sand pool for Grok Bot). Grok Bot’s weekly allowance is separate from Cursor’s monthly included bar; after weekly Grok runs out, spill may use Cursor on-demand. These calls can break when Cursor changes the API. Keys never leave the Keychain except to OpenAI and Anthropic.")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 480)
        .padding()
    }

    private func saveKeys() {
        let result = preferences.save()
        saveStatus = result
        if !result.isError {
            onSave()
        }
    }

    private func clockBinding(for zone: ClockTimeZoneChoice) -> Binding<Bool> {
        Binding(
            get: { clockPreferences.isEnabled(zone) },
            set: { on in
                clockPreferences.setEnabled(zone, on)
                onClockPreferencesChanged()
            }
        )
    }
}
