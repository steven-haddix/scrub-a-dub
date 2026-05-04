import Testing
@testable import ScrubadubCore

@Suite("ANSI.strip")
struct ANSITests {

    @Test("strips SGR color codes")
    func stripsSGR() {
        let input = "\u{1B}[31mred\u{1B}[0m and \u{1B}[1;32mbright green\u{1B}[0m"
        #expect(ANSI.strip(input) == "red and bright green")
    }

    @Test("strips cursor movement CSI sequences")
    func stripsCursor() {
        let input = "before\u{1B}[2K\u{1B}[1Aafter"
        #expect(ANSI.strip(input) == "beforeafter")
    }

    @Test("strips OSC sequences ending in BEL")
    func stripsOSCBel() {
        let input = "\u{1B}]0;window title\u{07}content"
        #expect(ANSI.strip(input) == "content")
    }

    @Test("strips OSC sequences ending in ST (\\x1B\\)")
    func stripsOSCST() {
        let input = "\u{1B}]8;;https://example.com\u{1B}\\link\u{1B}]8;;\u{1B}\\"
        #expect(ANSI.strip(input) == "link")
    }

    @Test("leaves text without escape codes unchanged")
    func leavesPlainText() {
        let input = "Hello, world! Nothing to see here."
        #expect(ANSI.strip(input) == input)
    }

    @Test("preserves leading/trailing whitespace (cleaner handles that)")
    func preservesWhitespace() {
        let input = "  \u{1B}[31mword\u{1B}[0m  "
        #expect(ANSI.strip(input) == "  word  ")
    }
}
