import AppKit
import Foundation
import ScrubadubCore

@MainActor
final class ClipboardWatcher {
    static let shared = ClipboardWatcher()

    private var timer: Timer?
    private var lastSeenChangeCount: Int
    private var lastWroteChangeCount: Int = -1

    private init() {
        self.lastSeenChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let settings = SettingsStore.shared
        guard settings.autoWatch else { return }

        let pb = NSPasteboard.general
        let cc = pb.changeCount
        guard cc != lastSeenChangeCount else { return }
        lastSeenChangeCount = cc

        guard cc != lastWroteChangeCount else { return }

        guard let raw = pb.string(forType: .string), !raw.isEmpty else { return }
        guard Heuristic.shouldClean(raw) else { return }

        let result = Cleaner.clean(raw, options: settings.cleanerOptions)
        guard result.didChange else { return }

        lastWroteChangeCount = ClipboardWriter.write(result.cleaned)
        lastSeenChangeCount = lastWroteChangeCount
    }
}
