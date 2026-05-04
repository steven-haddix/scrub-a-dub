import Foundation

public enum ANSI {
    public static func strip(_ input: String) -> String {
        var s = input
        s.replace(#/\x1B\[[0-?]*[ -/]*[@-~]/#, with: "")
        s.replace(#/\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)/#, with: "")
        s.replace(#/\x1B[()*+\-./][A-Za-z0-9@<=>?]/#, with: "")
        s.replace(#/\x1B[78=>FcDEHMNOPVWXYZ\\\]^_]/#, with: "")
        return s
    }
}
