import SwiftUI

struct SettingsView: View {
    @Bindable var panels: PanelController
    @Bindable var preferences: UsagePreferences
    @Bindable var clockPreferences: ClockPreferences
    var onSave: () -> Void
    var onClockPreferencesChanged: () -> Void

    @State private var saveStatus: UsageSaveResult?

    var body: some View {
        TabView {
            enableOnlyTab(isOn: $panels.showMemory)
                .tabItem { Text("App Memory") }
            clockTab
                .tabItem { Text("Clock") }
            enableOnlyTab(isOn: $panels.showNetwork)
                .tabItem { Text("Network") }
            enableOnlyTab(isOn: $panels.showSystem)
                .tabItem { Text("Computer") }
            usageTab
                .tabItem { Text("Usage") }
        }
        .frame(width: 520, height: 640)
    }

    private func enableOnlyTab(isOn: Binding<Bool>) -> some View {
        Form {
            Section {
                Toggle("Enable", isOn: isOn)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .padding()
    }

    private var clockTab: some View {
        Form {
            Section {
                Toggle("Enable", isOn: $panels.showClock)
            }

            Section("World clocks") {
                Text("Each enabled zone gets its own desktop panel when **Clock** is on in the menu bar. Sizing is free-form (not limited to WidgetKit tiles).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(ClockTimeZoneChoice.allCases) { zone in
                    Toggle(zone.menuTitle, isOn: clockBinding(for: zone))
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .padding()
    }

    private var usageTab: some View {
        Form {
            Section {
                Toggle("Enable", isOn: $panels.showUsage)
            }

            Section("Providers") {
                Toggle("Cursor (signed-in app session)", isOn: $preferences.cursorEnabled)
                Toggle("Grok Bot (weekly included quota)", isOn: $preferences.grokBotEnabled)
                Toggle("OpenAI", isOn: $preferences.openaiEnabled)
                Toggle("Anthropic", isOn: $preferences.anthropicEnabled)
            }

            Section("Keys") {
                SecureField("OpenAI Admin API key", text: $preferences.openaiKey)
                    .onSubmit(saveKeys)
                Button("Clear") {
                    preferences.clearOpenAIKey()
                    onSave()
                }
                Text("Paste an Admin key with api.usage.read.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("Anthropic Admin API key", text: $preferences.anthropicKey)
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
            } footer: {
                Text("Cursor and Grok Bot usage are unofficial: this app reads the local Cursor session and calls the same dashboard endpoints the website uses (monthly plan meter for Cursor, weekly Sand pool for Grok Bot). Grok Bot’s weekly allowance is separate from Cursor’s monthly included bar; after weekly Grok runs out, spill may use Cursor on-demand. These calls can break when Cursor changes the API. Keys never leave the Keychain except to OpenAI and Anthropic.")
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .padding()
    }

    private func saveKeys() {
        let result: UsageSaveResult = preferences.save()
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
