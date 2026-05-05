import Foundation

public struct CleanerOptions: Sendable, Codable, Equatable {
    public var stripAnsi: Bool
    public var normalizeBlankLines: Bool
    public var collapseBlankRuns: Bool
    public var stripBoxDrawing: Bool
    public var unwrapHardWrapped: Bool
    public var dedentCommonLeadingWhitespace: Bool

    public init(
        stripAnsi: Bool = true,
        normalizeBlankLines: Bool = true,
        collapseBlankRuns: Bool = false,
        stripBoxDrawing: Bool = false,
        unwrapHardWrapped: Bool = true,
        dedentCommonLeadingWhitespace: Bool = true
    ) {
        self.stripAnsi = stripAnsi
        self.normalizeBlankLines = normalizeBlankLines
        self.collapseBlankRuns = collapseBlankRuns
        self.stripBoxDrawing = stripBoxDrawing
        self.unwrapHardWrapped = unwrapHardWrapped
        self.dedentCommonLeadingWhitespace = dedentCommonLeadingWhitespace
    }

    public static let `default` = CleanerOptions()
}
