import Foundation

public enum Heuristic {
    public static func shouldClean(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard lines.count >= 3 else { return false }

        let nonEmpty = lines.filter { line in
            !line.isEmpty && !line.allSatisfy(\.isWhitespace)
        }
        guard !nonEmpty.isEmpty else { return false }

        let padded = nonEmpty.filter { line in
            var count = 0
            for ch in line.reversed() {
                if ch == " " { count += 1 } else { break }
                if count >= 2 { return true }
            }
            return false
        }

        return Double(padded.count) / Double(nonEmpty.count) >= 0.5
    }
}
