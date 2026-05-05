import Foundation
import ScrubadubCore

let raw = FileHandle.standardInput.readDataToEndOfFile()
guard let input = String(data: raw, encoding: .utf8) else {
    FileHandle.standardError.write(Data("scrubadub: input is not valid UTF-8\n".utf8))
    exit(1)
}

let result = Cleaner.clean(input, options: .default)
FileHandle.standardOutput.write(Data(result.cleaned.utf8))

let stats = "scrubadub: stripped \(result.strippedCharCount) chars from \(result.lineCount) lines\n"
FileHandle.standardError.write(Data(stats.utf8))
