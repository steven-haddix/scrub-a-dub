import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("Cleanup") {
                Toggle("Rejoin hard-wrapped paragraphs", isOn: $settings.unwrapHardWrapped)
                Text("Joins lines that the terminal hard-wrapped at width. Skips bullets, headers, tables, and lines ending in . ! ?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Strip ANSI escape codes", isOn: $settings.stripAnsi)
                Toggle("Trim outer blank lines", isOn: $settings.normalizeBlankLines)
                Toggle("Collapse 3+ consecutive blank lines", isOn: $settings.collapseBlankRuns)
                Toggle("Strip box-drawing borders & gutters", isOn: $settings.stripBoxDrawing)
            }
            Section("Behavior") {
                Toggle("Auto-watch clipboard", isOn: $settings.autoWatch)
                Text("When on, Scrubadub silently rewrites the clipboard whenever it detects obvious terminal padding (≥3 lines, ≥50% with trailing whitespace).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("About") {
                LabeledContent("Version", value: "0.1.0")
                Text("Trailing whitespace per line is always stripped — that's the whole job.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 420)
    }
}
