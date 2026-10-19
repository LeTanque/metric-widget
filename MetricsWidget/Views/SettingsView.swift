import SwiftUI

struct SettingsView: View {
    @Bindable var panels: PanelController
    @Bindable var themes: ThemeStore
    @Bindable var preferences: UsagePreferences
    @Bindable var clockPreferences: ClockPreferences
    var onSave: () -> Void
    var onClockPreferencesChanged: () -> Void

    @State private var saveStatus: UsageSaveResult?
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        VStack(spacing: 0) {
            Picker("Settings", selection: $selectedSection) {
                ForEach(SettingsSection.allCases) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .top])

            sectionContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 640)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .general:
            generalTab
        case .appMemory:
            enableOnlyTab(isOn: $panels.showMemory)
        case .clock:
            clockTab
        case .network:
            enableOnlyTab(isOn: $panels.showNetwork)
        case .computer:
            enableOnlyTab(isOn: $panels.showSystem)
        case .usage:
            usageTab
        }
    }

    private var generalTab: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $panels.themeID) {
                    ForEach(ThemeID.allCases) { theme in
                        Text(theme.menuTitle).tag(theme)
                    }
                }
                // Color Theme and picture rows only apply to Custom, so they hide otherwise.
                if panels.themeID == .custom {
                    Picker("Color Theme", selection: $panels.customColorTheme) {
                        ForEach(CustomColorTheme.allCases) { ink in
                            Text(ink.menuTitle).tag(ink)
                        }
                    }
                    VStack(alignment: .trailing, spacing: 6) {
                        Button("Choose Picture…") {
                            panels.chooseCustomBackground()
                        }
                        if let name = themes.customBackgroundFileName {
                            HStack(spacing: 6) {
                                Spacer(minLength: 0)
                                Text(name)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundStyle(.secondary)
                                    .help(name)
                                RemovePictureButton {
                                    panels.removeCustomBackground()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .padding()
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
                if preferences.openaiEnabled {
                    Toggle("ChatGPT plan limits (5-hour, weekly)", isOn: $preferences.openaiPlanLimitsEnabled)
                    Text("Unofficial: uses your Codex sign-in (~/.codex) to read the limits Codex /status shows; falls back to the latest Codex session log. No Admin key needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Toggle("Anthropic", isOn: $preferences.anthropicEnabled)
            }

            Section("Status") {
                Toggle("Show service status", isOn: Bindable(panels.providerStatus).enabled)
                Text("Display status for enabled provider.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                TextField("OpenAI monthly budget (USD)", text: $preferences.openaiMonthlyBudget)
                    .onSubmit(saveKeys)
                Text("Leave blank or 0 for no budget.")
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

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case appMemory = "App Memory"
    case clock = "Clock"
    case network = "Network"
    case computer = "Computer"
    case usage = "Usage"

    var id: String { rawValue }
}

/// Small red circle with a black ⓧ; removes the custom picture.
private struct RemovePictureButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
        .help("Remove picture")
        .accessibilityLabel("Remove picture")
    }
}
