import AppKit
import ScrubadubCore
import SwiftUI

struct PasteCatcher: NSViewRepresentable {
    let cleanerOptions: CleanerOptions
    let onResult: (CleanResult) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(cleanerOptions: cleanerOptions, onResult: onResult)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false

        let textView = PasteCatcherTextView()
        textView.coordinator = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 6, height: 6)

        scroll.documentView = textView

        DispatchQueue.main.async { [weak textView] in
            textView?.window?.makeFirstResponder(textView)
        }
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.cleanerOptions = cleanerOptions
        context.coordinator.onResult = onResult
    }

    final class Coordinator {
        var cleanerOptions: CleanerOptions
        var onResult: (CleanResult) -> Void

        init(cleanerOptions: CleanerOptions, onResult: @escaping (CleanResult) -> Void) {
            self.cleanerOptions = cleanerOptions
            self.onResult = onResult
        }
    }
}

private final class PasteCatcherTextView: NSTextView {
    weak var coordinator: PasteCatcher.Coordinator?

    override func paste(_ sender: Any?) {
        guard
            let coordinator,
            let raw = NSPasteboard.general.string(forType: .string)
        else {
            super.paste(sender)
            return
        }

        let result = Cleaner.clean(raw, options: coordinator.cleanerOptions)

        ClipboardWriter.write(result.cleaned)

        self.string = result.cleaned
        self.scrollToBeginningOfDocument(nil)

        coordinator.onResult(result)
    }
}
