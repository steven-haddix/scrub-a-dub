import Foundation

public struct CleanResult: Sendable, Equatable {
    public let cleaned: String
    public let original: String
    public let strippedCharCount: Int
    public let lineCount: Int

    public init(cleaned: String, original: String, strippedCharCount: Int, lineCount: Int) {
        self.cleaned = cleaned
        self.original = original
        self.strippedCharCount = strippedCharCount
        self.lineCount = lineCount
    }

    public var didChange: Bool { cleaned != original }
}
