import AppKit
import ScrubadubCore
import SwiftUI

struct PopoverView: View {
    @Environment(SettingsStore.self) private var settings
    @State private var lastResult: CleanResult?
    @State private var undoUsed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Scrubadub").font(.headline)
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit Scrubadub")
            }

            PasteCatcher(cleanerOptions: settings.cleanerOptions) { result in
                lastResult = result
                undoUsed = false
            }
            .frame(height: 200)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))

            statusLine
        }
        .padding(14)
        .frame(width: 480)
    }

    @ViewBuilder
    private var statusLine: some View {
        if let r = lastResult {
            HStack(spacing: 6) {
                Text("🦆")
                if undoUsed {
                    Text("Restored original to clipboard.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Quack! Cleaned & copied —")
                        .foregroundStyle(.secondary)
                    Text("stripped \(r.strippedCharCount) char\(r.strippedCharCount == 1 ? "" : "s") from \(r.lineCount) line\(r.lineCount == 1 ? "" : "s")")
                        .fontWeight(.medium)
                }
                Spacer()
                if !undoUsed {
                    Button("↩ Use original") {
                        ClipboardWriter.write(r.original)
                        undoUsed = true
                    }
                    .buttonStyle(.borderless)
                    .help("Restore the pre-clean clipboard contents")
                }
            }
            .font(.callout)
        } else {
            Text("Paste something gross. ⌘V")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}
