import Testing
@testable import ScrubadubCore

@Suite("Cleaner")
struct CleanerTests {

    @Test("strips trailing whitespace per line (always)")
    func stripsTrailingWhitespace() {
        let input = "hello   \nworld    \nfoo  "
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: false, unwrapHardWrapped: false))
        #expect(r.cleaned == "hello\nworld\nfoo")
        #expect(r.strippedCharCount == 9)
    }

    @Test("space-only lines become empty after trailing strip")
    func spaceOnlyLinesBecomeEmpty() {
        let input = "alpha\n   \nbeta"
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: false, unwrapHardWrapped: false))
        #expect(r.cleaned == "alpha\n\nbeta")
    }

    @Test("trims leading and trailing blank lines when normalizeBlankLines is on")
    func trimsOuterBlanks() {
        let input = "   \n\n  hello  \n\n   "
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: true, unwrapHardWrapped: false))
        #expect(r.cleaned == "  hello")
    }

    @Test("preserves internal blank lines when normalizeBlankLines is on")
    func preservesInternalBlanks() {
        let input = "a\n\nb\n\n\nc"
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: true, unwrapHardWrapped: false))
        #expect(r.cleaned == "a\n\nb\n\n\nc")
    }

    @Test("collapseBlankRuns reduces 3+ blanks to 1")
    func collapsesBlankRuns() {
        let input = "a\n\n\n\nb\n\nc"
        let r = Cleaner.clean(input, options: CleanerOptions(
            stripAnsi: false, normalizeBlankLines: false, collapseBlankRuns: true, unwrapHardWrapped: false
        ))
        #expect(r.cleaned == "a\n\nb\n\nc")
    }

    @Test("preserves trailing newline when present in input")
    func preservesTrailingNewline() {
        let input = "hello   \n"
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: false, unwrapHardWrapped: false))
        #expect(r.cleaned == "hello\n")
    }

    @Test("preserves indentation on bullet lines")
    func preservesIndentation() {
        let input = "  - item one    \n  - item two   "
        let r = Cleaner.clean(input, options: CleanerOptions(unwrapHardWrapped: false))
        #expect(r.cleaned == "  - item one\n  - item two")
    }

    @Test("strips box-drawing pure-border lines and leading gutters")
    func stripsBoxDrawing() {
        let input = """
        ╭──────────────╮
        │ hello world  │
        │ foo          │
        ╰──────────────╯
        """
        let r = Cleaner.clean(input, options: CleanerOptions(
            stripAnsi: false, normalizeBlankLines: true, stripBoxDrawing: true, unwrapHardWrapped: false
        ))
        #expect(r.cleaned == "hello world  │\nfoo          │")
    }

    @Test("normalizes CRLF line endings to LF")
    func normalizesLineEndings() {
        let input = "a   \r\nb   \r\nc"
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: false, unwrapHardWrapped: false))
        #expect(r.cleaned == "a\nb\nc")
    }

    @Test("CleanResult.didChange reflects whether anything was modified")
    func didChangeFlag() {
        let clean = Cleaner.clean("nothing to do")
        #expect(!clean.didChange)
        let dirty = Cleaner.clean("something  ")
        #expect(dirty.didChange)
    }

    // MARK: - Hard-wrapped paragraph unwrap

    @Test("joins hard-wrapped continuation that ends with comma")
    func unwrapsCommaContinuation() {
        let pad = String(repeating: " ", count: 14)
        let input = [
            "  TL;DR: long sentence that wraps because terminal too narrow (Sarah_Ad_v2,\(pad)",
            "  Aging_04282026), so paid-social caretaker signups are effectively dead-on-arrival.",
        ].joined(separator: "\n")

        let r = Cleaner.clean(input)
        #expect(r.cleaned == "  TL;DR: long sentence that wraps because terminal too narrow (Sarah_Ad_v2, Aging_04282026), so paid-social caretaker signups are effectively dead-on-arrival.")
    }

    @Test("does NOT join across bullet boundaries")
    func keepsBulletsSeparate() {
        let pad = String(repeating: " ", count: 200)
        let input = [
            "  - First bullet that is fairly long and reaches near terminal width but ends here.\(pad)",
            "  - Second bullet starts on its own line.",
        ].joined(separator: "\n")
        let r = Cleaner.clean(input)
        let lines = r.cleaned.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].hasPrefix("  - First bullet"))
        #expect(lines[1].hasPrefix("  - Second bullet"))
    }

    @Test("does NOT join when previous line ends with sentence period")
    func keepsParagraphsSeparate() {
        let pad = String(repeating: " ", count: 200)
        let input = [
            "First paragraph that is long and ends with a period.\(pad)",
            "Second paragraph that is also long and starts here.",
        ].joined(separator: "\n")
        let r = Cleaner.clean(input)
        let lines = r.cleaned.components(separatedBy: "\n")
        #expect(lines.count == 2)
    }

    @Test("does NOT join into table rows or borders")
    func keepsTableRowsSeparate() {
        let pad = String(repeating: " ", count: 200)
        let input = [
            "Some long paragraph that wraps near terminal width without a period at the end\(pad)",
            "  ┌──────┬──────┐",
            "  │ a    │ b    │",
            "  └──────┴──────┘",
        ].joined(separator: "\n")
        let r = Cleaner.clean(input)
        let lines = r.cleaned.components(separatedBy: "\n")
        #expect(lines.count == 4)
        #expect(lines[1].hasPrefix("  ┌"))
    }

    @Test("does NOT unwrap when input has no long lines")
    func skipsShortInput() {
        let input = "short\nlines\nhere"
        let r = Cleaner.clean(input, options: CleanerOptions(unwrapHardWrapped: true))
        #expect(r.cleaned == "short\nlines\nhere")
    }

    @Test("unwrap can be disabled via option")
    func unwrapDisabled() {
        let pad = String(repeating: " ", count: 14)
        let input = "Sentence with comma,\(pad)\ncontinuation here."
        let r = Cleaner.clean(input, options: CleanerOptions(unwrapHardWrapped: false))
        #expect(r.cleaned == "Sentence with comma,\ncontinuation here.")
    }

    @Test("does NOT join across blank lines")
    func keepsParagraphsAcrossBlanks() {
        let pad = String(repeating: " ", count: 200)
        let input = [
            "First paragraph long line that doesn't end with period\(pad)",
            "",
            "Second paragraph starts fresh.",
        ].joined(separator: "\n")
        let r = Cleaner.clean(input, options: CleanerOptions(stripAnsi: false, normalizeBlankLines: false))
        let lines = r.cleaned.components(separatedBy: "\n")
        #expect(lines.count == 3)
        #expect(lines[1].isEmpty)
    }

    @Test("golden: user's actual Claude CLI paste sample with wrapped bullet")
    func goldenClaudePaste() {
        let pad = String(repeating: " ", count: 200)
        let input = [
            "  Pattern confirmation\(pad)",
            String(repeating: " ", count: 200),
            "  - Every FB/IG event lands on /signup?action=signup&jid=… — the caretaker invite flow (jid = invite token).\(pad)",
            "  - 3 events carry paid-ad UTMs directly (#4 Instagram_Feed/Aging_04282026, #6 Instagram_Reels/Sarah_Ad_v2, #8 Facebook_Mobile_Feed/Sarah_Ad_v2). The other 5 have no UTM but arrived via FB/IG in-app browsers — likely organic shares of the invite link opened inside the\(pad)",
            "  Facebook/Instagram apps.\(pad)",
            "  - Event #1 and #2 are the same session 35 seconds apart — user got interaction_in_progress, presumably retried, hit timed_out. So 7 errors represent ~7 distinct attempted signups.",
            "  - #3 (Edge / copilot.com) is the outlier — desktop Edge with utm_source=copilot.com is almost certainly Microsoft Copilot prefetching/agent-fetching the URL, not a human attempting signup. ",
        ].joined(separator: "\n")

        let expected = [
            "  Pattern confirmation",
            "",
            "  - Every FB/IG event lands on /signup?action=signup&jid=… — the caretaker invite flow (jid = invite token).",
            "  - 3 events carry paid-ad UTMs directly (#4 Instagram_Feed/Aging_04282026, #6 Instagram_Reels/Sarah_Ad_v2, #8 Facebook_Mobile_Feed/Sarah_Ad_v2). The other 5 have no UTM but arrived via FB/IG in-app browsers — likely organic shares of the invite link opened inside the Facebook/Instagram apps.",
            "  - Event #1 and #2 are the same session 35 seconds apart — user got interaction_in_progress, presumably retried, hit timed_out. So 7 errors represent ~7 distinct attempted signups.",
            "  - #3 (Edge / copilot.com) is the outlier — desktop Edge with utm_source=copilot.com is almost certainly Microsoft Copilot prefetching/agent-fetching the URL, not a human attempting signup.",
        ].joined(separator: "\n")

        let r = Cleaner.clean(input)
        #expect(r.cleaned == expected)
        #expect(r.didChange)
        #expect(r.strippedCharCount > 1000)
    }
}
