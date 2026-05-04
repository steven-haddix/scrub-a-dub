import AppKit

enum ClipboardWriter {
    static func read() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    @discardableResult
    static func write(_ text: String) -> Int {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        return pb.changeCount
    }
}
