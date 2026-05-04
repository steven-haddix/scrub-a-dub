import Testing
@testable import ScrubadubCore

@Suite("Heuristic.shouldClean")
struct HeuristicTests {

    @Test("triggers on ≥3 lines with ≥50% padded by ≥2 trailing spaces")
    func triggersOnObviousPadding() {
        let pad = String(repeating: " ", count: 100)
        let text = "alpha\(pad)\nbeta\(pad)\ngamma\(pad)"
        #expect(Heuristic.shouldClean(text))
    }

    @Test("does not trigger on a single-line URL")
    func ignoresSingleLine() {
        #expect(!Heuristic.shouldClean("https://example.com/path?q=1"))
    }

    @Test("does not trigger on 2-line snippet without trailing whitespace")
    func ignoresTwoLineClean() {
        #expect(!Heuristic.shouldClean("line one\nline two"))
    }

    @Test("does not trigger on multi-line code with no padding")
    func ignoresCleanCode() {
        let code = """
        func hello() {
            print("world")
        }
        """
        #expect(!Heuristic.shouldClean(code))
    }

    @Test("does not trigger when only 1 single trailing space per line")
    func ignoresOneSpaceTrails() {
        let text = "a \nb \nc \nd "
        #expect(!Heuristic.shouldClean(text))
    }

    @Test("triggers when exactly half of non-empty lines are padded")
    func triggersAtFiftyPercent() {
        let pad = String(repeating: " ", count: 50)
        let text = "alpha\(pad)\nbeta\nfoo\(pad)\nbar"
        #expect(Heuristic.shouldClean(text))
    }

    @Test("ignores blank-only lines when computing ratio")
    func ignoresBlankLines() {
        let pad = String(repeating: " ", count: 50)
        let text = "\n\nalpha\(pad)\nbeta\(pad)\ngamma\(pad)\n\n"
        #expect(Heuristic.shouldClean(text))
    }

    @Test("does not trigger on empty input")
    func ignoresEmpty() {
        #expect(!Heuristic.shouldClean(""))
    }
}
