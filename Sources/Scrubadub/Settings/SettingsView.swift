import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("Cleanup") {
                Toggle("Rejoin hard-wrapped paragraphs", isOn: $settings.unwrapHardWrapped)
                Text("Joins terminal-wrapped prose back into normal paragraphs while leaving bullets, tables, and headings alone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Strip ANSI escape codes", isOn: $settings.stripAnsi)
                Text("Removes hidden terminal color and formatting codes before copying the cleaned text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Trim outer blank lines", isOn: $settings.normalizeBlankLines)
                Text("Deletes empty lines at the very beginning and end of the pasted text.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Collapse 3+ consecutive blank lines", isOn: $settings.collapseBlankRuns)
                Text("Turns long runs of blank lines into a single blank line.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle("Strip box-drawing borders & gutters", isOn: $settings.stripBoxDrawing)
                Text("Removes common terminal box borders and margin gutters from copied output.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Behavior") {
                Toggle("Auto-watch clipboard", isOn: $settings.autoWatch)
                Text("Silently rewrites the clipboard when Scrubadub detects obvious terminal padding.")
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
        .frame(width: 480, height: 540)
    }
}
