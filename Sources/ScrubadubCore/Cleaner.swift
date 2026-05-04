import Foundation

public enum Cleaner {
    private static let borderChars: Set<Character> = [
        "╭", "╮", "╰", "╯", "─", "━", "═", "┄", "┅", "│", "┃", "║",
        "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
        "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
    ]
    private static let gutterChars: Set<Character> = ["│", "┃", "║"]
    private static let closingPunctuation: Set<Character> = [
        "\"", "'", "”", "’", ")", "]", "»", "›", "”", "›",
    ]

    public static func clean(_ input: String, options: CleanerOptions = .default) -> CleanResult {
        let hadTrailingNewline = input.last.map { $0 == "\n" || $0 == "\r" } ?? false

        var working = input
        if options.stripAnsi {
            working = ANSI.strip(working)
        }

        var lines = splitLines(working)
        lines = lines.map(stripTrailing)

        if options.unwrapHardWrapped {
            lines = unwrapHardWrapped(lines)
        }

        if options.stripBoxDrawing {
            lines = lines.compactMap(stripBoxDrawing)
        }

        if options.collapseBlankRuns {
            lines = collapseBlankRuns(lines)
        }

        if options.normalizeBlankLines {
            while lines.first?.isEmpty == true { lines.removeFirst() }
            while lines.last?.isEmpty == true { lines.removeLast() }
        }

        var cleaned = lines.joined(separator: "\n")
        if hadTrailingNewline && !cleaned.isEmpty && !cleaned.hasSuffix("\n") {
            cleaned += "\n"
        }

        let stripped = max(0, input.count - cleaned.count)
        return CleanResult(
            cleaned: cleaned,
            original: input,
            strippedCharCount: stripped,
            lineCount: lines.count
        )
    }

    private static func splitLines(_ s: String) -> [String] {
        s.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func stripTrailing(_ line: String) -> String {
        var l = line
        while let last = l.last, last.isWhitespace { l.removeLast() }
        return l
    }

    private static func stripBoxDrawing(_ line: String) -> String? {
        if line.isEmpty { return line }
        let nonSpace = line.filter { !$0.isWhitespace }
        if nonSpace.isEmpty { return line }
        if nonSpace.allSatisfy({ borderChars.contains($0) }) {
            return nil
        }
        var l = line
        if let first = l.first, gutterChars.contains(first) {
            l.removeFirst()
            if l.first == " " { l.removeFirst() }
        }
        return l
    }

    private static func collapseBlankRuns(_ lines: [String]) -> [String] {
        var out: [String] = []
        var lastWasBlank = false
        for line in lines {
            let isBlank = line.isEmpty
            if isBlank && lastWasBlank { continue }
            out.append(line)
            lastWasBlank = isBlank
        }
        return out
    }

    private static func unwrapHardWrapped(_ lines: [String]) -> [String] {
        let maxLen = lines.lazy.filter { !$0.isEmpty }.map(\.count).max() ?? 0
        guard maxLen >= 60 else { return lines }
        let threshold = maxLen - 30

        var out: [String] = []
        for line in lines {
            if let prev = out.last, shouldJoin(prev: prev, curr: line, threshold: threshold) {
                let trimmed = line.drop(while: \.isWhitespace)
                out[out.count - 1] = prev + " " + String(trimmed)
            } else {
                out.append(line)
            }
        }
        return out
    }

    private static func shouldJoin(prev: String, curr: String, threshold: Int) -> Bool {
        if prev.isEmpty || curr.isEmpty { return false }
        if prev.count < threshold { return false }
        if endsWithSentenceTerminator(prev) { return false }
        if isStructuralLine(prev) || isStructuralLine(curr) { return false }
        if startsWithListMarker(curr) { return false }
        if startsWithHeading(curr) { return false }
        return true
    }

    private static func endsWithSentenceTerminator(_ s: String) -> Bool {
        var i = s.endIndex
        while i > s.startIndex {
            i = s.index(before: i)
            let c = s[i]
            if closingPunctuation.contains(c) { continue }
            return c == "." || c == "!" || c == "?" || c == "…"
        }
        return false
    }

    private static func startsWithListMarker(_ s: String) -> Bool {
        let trimmed = s.drop(while: \.isWhitespace)
        guard let first = trimmed.first else { return false }
        if first == "-" || first == "*" || first == "•" || first == "+" || first == ">" {
            let next = trimmed.dropFirst().first
            return next == " " || next == nil
        }
        if first.isNumber {
            var idx = trimmed.startIndex
            while idx < trimmed.endIndex, trimmed[idx].isNumber {
                idx = trimmed.index(after: idx)
            }
            guard idx < trimmed.endIndex else { return false }
            let mark = trimmed[idx]
            guard mark == "." || mark == ")" else { return false }
            let after = trimmed.index(after: idx)
            return after < trimmed.endIndex && trimmed[after] == " "
        }
        return false
    }

    private static func startsWithHeading(_ s: String) -> Bool {
        let trimmed = s.drop(while: \.isWhitespace)
        return trimmed.first == "#"
    }

    private static func isStructuralLine(_ s: String) -> Bool {
        let trimmed = s.drop(while: \.isWhitespace)
        guard let first = trimmed.first else { return false }
        return borderChars.contains(first)
    }
}
