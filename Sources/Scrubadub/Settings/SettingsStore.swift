import Foundation
import Observation
import ScrubadubCore

@Observable
final class SettingsStore {
    @MainActor static let shared = SettingsStore()

    private enum Key {
        static let stripAnsi = "stripAnsi"
        static let normalizeBlankLines = "normalizeBlankLines"
        static let collapseBlankRuns = "collapseBlankRuns"
        static let stripBoxDrawing = "stripBoxDrawing"
        static let unwrapHardWrapped = "unwrapHardWrapped"
        static let autoWatch = "autoWatch"
    }

    var stripAnsi: Bool { didSet { UserDefaults.standard.set(stripAnsi, forKey: Key.stripAnsi) } }
    var normalizeBlankLines: Bool { didSet { UserDefaults.standard.set(normalizeBlankLines, forKey: Key.normalizeBlankLines) } }
    var collapseBlankRuns: Bool { didSet { UserDefaults.standard.set(collapseBlankRuns, forKey: Key.collapseBlankRuns) } }
    var stripBoxDrawing: Bool { didSet { UserDefaults.standard.set(stripBoxDrawing, forKey: Key.stripBoxDrawing) } }
    var unwrapHardWrapped: Bool { didSet { UserDefaults.standard.set(unwrapHardWrapped, forKey: Key.unwrapHardWrapped) } }
    var autoWatch: Bool { didSet { UserDefaults.standard.set(autoWatch, forKey: Key.autoWatch) } }

    private init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            Key.stripAnsi: true,
            Key.normalizeBlankLines: true,
            Key.collapseBlankRuns: false,
            Key.stripBoxDrawing: false,
            Key.unwrapHardWrapped: true,
            Key.autoWatch: false,
        ])
        self.stripAnsi = d.bool(forKey: Key.stripAnsi)
        self.normalizeBlankLines = d.bool(forKey: Key.normalizeBlankLines)
        self.collapseBlankRuns = d.bool(forKey: Key.collapseBlankRuns)
        self.stripBoxDrawing = d.bool(forKey: Key.stripBoxDrawing)
        self.unwrapHardWrapped = d.bool(forKey: Key.unwrapHardWrapped)
        self.autoWatch = d.bool(forKey: Key.autoWatch)
    }

    var cleanerOptions: CleanerOptions {
        CleanerOptions(
            stripAnsi: stripAnsi,
            normalizeBlankLines: normalizeBlankLines,
            collapseBlankRuns: collapseBlankRuns,
            stripBoxDrawing: stripBoxDrawing,
            unwrapHardWrapped: unwrapHardWrapped
        )
    }
}
