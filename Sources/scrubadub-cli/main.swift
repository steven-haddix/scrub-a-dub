import Foundation
import ScrubadubCore

let usage = """
Usage: scrubadub [--help] [--version]

Cleans padded terminal output from standard input and writes the result to standard output.

Options:
  -h, --help       Show this help message.
  -v, --version    Show the Scrubadub version.

Examples:
  pbpaste | scrubadub | pbcopy
  scrubadub < messy-output.txt > clean-output.txt
"""

let arguments = Array(CommandLine.arguments.dropFirst())

func writeStandardOutput(_ text: String) {
    FileHandle.standardOutput.write(Data(text.utf8))
}

func writeStandardError(_ text: String) {
    FileHandle.standardError.write(Data(text.utf8))
}

switch arguments {
case []:
    break
case ["--help"], ["-h"], ["help"]:
    writeStandardOutput(usage + "\n")
    exit(0)
case ["--version"], ["-v"], ["version"]:
    writeStandardOutput("scrubadub \(ScrubadubVersion.current)\n")
    exit(0)
default:
    writeStandardError("scrubadub: unknown argument: \(arguments.joined(separator: " "))\n\n")
    writeStandardError(usage + "\n")
    exit(64)
}

let raw = FileHandle.standardInput.readDataToEndOfFile()
guard let input = String(data: raw, encoding: .utf8) else {
    writeStandardError("scrubadub: input is not valid UTF-8\n")
    exit(1)
}

let result = Cleaner.clean(input, options: .default)
writeStandardOutput(result.cleaned)

let stats = "scrubadub: stripped \(result.strippedCharCount) chars from \(result.lineCount) lines\n"
writeStandardError(stats)
