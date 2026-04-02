#if os(macOS)
import Foundation

final class SourceKitLSPClient: @unchecked Sendable {
    static let shared = SourceKitLSPClient()

    private let lock = NSLock()
    private var state: State?

    private init() {
        state = try? State()
    }

    func semanticTokens(for source: String, kind: ObjCFileKind) -> [ObjCSemanticToken]? {
        lock.lock()
        defer { lock.unlock() }

        if state?.isRunning != true {
            state = try? State()
        }

        guard let state else {
            return nil
        }

        do {
            return try state.semanticTokens(for: source, kind: kind)
        } catch {
            self.state = nil
            return nil
        }
    }
}

private final class State {
    private struct Legend {
        let tokenTypes: [String]
        let tokenModifiers: [String]
    }

    private let process: Process
    private let inputHandle: FileHandle
    private let outputHandle: FileHandle
    private let workspaceURL: URL
    private let fileURLs: [ObjCFileKind: URL]
    private var legend: Legend
    private var nextRequestID = 100
    private var nextVersion = 1
    private var openedKinds: Set<ObjCFileKind> = []

    init() throws {
        let sourceKitLSPPath = try Self.commandOutput("/usr/bin/xcrun", arguments: ["--find", "sourcekit-lsp"])
        let sdkPath = try Self.commandOutput("/usr/bin/xcrun", arguments: ["--sdk", "macosx", "--show-sdk-path"])

        let workspaceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("syntaxink-objc-lsp-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)

        let headerURL = workspaceURL.appendingPathComponent(ObjCFileKind.header.rawValue)
        let implementationURL = workspaceURL.appendingPathComponent(ObjCFileKind.implementation.rawValue)
        try "".write(to: headerURL, atomically: true, encoding: .utf8)
        try "".write(to: implementationURL, atomically: true, encoding: .utf8)

        let compileCommands = [
            Self.compileCommand(for: headerURL, kind: .header, workspaceURL: workspaceURL, sdkPath: sdkPath),
            Self.compileCommand(for: implementationURL, kind: .implementation, workspaceURL: workspaceURL, sdkPath: sdkPath),
        ]
        let compileCommandsURL = workspaceURL.appendingPathComponent("compile_commands.json")
        let compileCommandsData = try JSONSerialization.data(withJSONObject: compileCommands, options: [.prettyPrinted, .sortedKeys])
        try compileCommandsData.write(to: compileCommandsURL)

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sourceKitLSPPath)
        process.arguments = ["--default-workspace-type", "compilationDatabase", "--compilation-db-search-path", "."]
        process.currentDirectoryURL = workspaceURL
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = try FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        try process.run()

        self.process = process
        self.inputHandle = inputPipe.fileHandleForWriting
        self.outputHandle = outputPipe.fileHandleForReading
        self.workspaceURL = workspaceURL
        self.fileURLs = [
            .header: headerURL,
            .implementation: implementationURL,
        ]
        self.legend = Legend(tokenTypes: [], tokenModifiers: [])

        let initializeID = 1
        try send([
            "jsonrpc": "2.0",
            "id": initializeID,
            "method": "initialize",
            "params": [
                "processId": NSNull(),
                "clientInfo": [
                    "name": "SyntaxInk",
                    "version": "1",
                ],
                "rootUri": workspaceURL.absoluteString,
                "capabilities": [
                    "textDocument": [
                        "semanticTokens": [
                            "tokenTypes": [],
                            "tokenModifiers": [],
                            "requests": ["full": true],
                            "formats": ["relative"],
                        ],
                    ],
                ],
                "workspaceFolders": [[
                    "uri": workspaceURL.absoluteString,
                    "name": workspaceURL.lastPathComponent,
                ]],
            ],
        ])

        let initializeResponse = try waitForResponse(id: initializeID)
        guard
            let result = initializeResponse["result"] as? [String: Any],
            let capabilities = result["capabilities"] as? [String: Any],
            let semanticProvider = capabilities["semanticTokensProvider"] as? [String: Any],
            let legend = semanticProvider["legend"] as? [String: Any],
            let tokenTypes = legend["tokenTypes"] as? [String],
            let tokenModifiers = legend["tokenModifiers"] as? [String]
        else {
            throw NSError(domain: "SourceKitLSPClient", code: 1)
        }

        self.legend = Legend(tokenTypes: tokenTypes, tokenModifiers: tokenModifiers)

        try send([
            "jsonrpc": "2.0",
            "method": "initialized",
            "params": [:],
        ])
    }

    deinit {
        try? closeOpenDocuments()
        if process.isRunning {
            try? send([
                "jsonrpc": "2.0",
                "id": nextRequestID,
                "method": "shutdown",
                "params": [:],
            ])
            nextRequestID += 1
            try? send([
                "jsonrpc": "2.0",
                "method": "exit",
                "params": [:],
            ])
            process.terminate()
        }

        try? FileManager.default.removeItem(at: workspaceURL)
    }

    var isRunning: Bool {
        process.isRunning
    }

    func semanticTokens(for source: String, kind: ObjCFileKind) throws -> [ObjCSemanticToken] {
        let fileURL = fileURLs[kind]!
        try source.write(to: fileURL, atomically: true, encoding: .utf8)

        if openedKinds.contains(kind) {
            try send([
                "jsonrpc": "2.0",
                "method": "textDocument/didClose",
                "params": [
                    "textDocument": ["uri": fileURL.absoluteString],
                ],
            ])
            openedKinds.remove(kind)
        }

        try send([
            "jsonrpc": "2.0",
            "method": "textDocument/didOpen",
            "params": [
                "textDocument": [
                    "uri": fileURL.absoluteString,
                    "languageId": "objective-c",
                    "version": nextVersion,
                    "text": source,
                ],
            ],
        ])
        nextVersion += 1
        openedKinds.insert(kind)

        let requestID = nextRequestID
        nextRequestID += 1

        try send([
            "jsonrpc": "2.0",
            "id": requestID,
            "method": "textDocument/semanticTokens/full",
            "params": [
                "textDocument": ["uri": fileURL.absoluteString],
            ],
        ])

        let response = try waitForResponse(id: requestID)
        guard
            let result = response["result"] as? [String: Any],
            let data = result["data"] as? [NSNumber]
        else {
            return []
        }

        return decodeTokens(from: data.map(\.intValue), source: source)
    }

    private func closeOpenDocuments() throws {
        for kind in openedKinds {
            guard let fileURL = fileURLs[kind] else { continue }
            try send([
                "jsonrpc": "2.0",
                "method": "textDocument/didClose",
                "params": [
                    "textDocument": ["uri": fileURL.absoluteString],
                ],
            ])
        }
        openedKinds.removeAll()
    }

    private func decodeTokens(from encodedTokens: [Int], source: String) -> [ObjCSemanticToken] {
        let lineStarts = Self.lineStartOffsets(in: source)
        let string = source as NSString

        var line = 0
        var column = 0
        var tokens: [ObjCSemanticToken] = []

        for index in stride(from: 0, to: encodedTokens.count, by: 5) {
            guard index + 4 < encodedTokens.count else { break }

            let deltaLine = encodedTokens[index]
            let deltaStart = encodedTokens[index + 1]
            let length = encodedTokens[index + 2]
            let tokenTypeIndex = encodedTokens[index + 3]
            let tokenModifiersBitmask = encodedTokens[index + 4]

            line += deltaLine
            column = deltaLine == 0 ? column + deltaStart : deltaStart

            guard line < lineStarts.count else { continue }
            let location = lineStarts[line] + column
            let range = NSRange(location: location, length: length)
            guard NSMaxRange(range) <= string.length else { continue }

            let tokenType = legend.tokenTypes[tokenTypeIndex]
            let tokenModifiers = Set(legend.tokenModifiers.enumerated().compactMap { index, modifier in
                (tokenModifiersBitmask & (1 << index)) != 0 ? modifier : nil
            })

            tokens.append(ObjCSemanticToken(
                text: string.substring(with: range),
                range: range,
                tokenType: tokenType,
                tokenModifiers: tokenModifiers
            ))
        }

        return tokens
    }

    private func send(_ message: [String: Any]) throws {
        let body = try JSONSerialization.data(withJSONObject: message, options: [.sortedKeys])
        let header = Data("Content-Length: \(body.count)\r\n\r\n".utf8)
        inputHandle.write(header)
        inputHandle.write(body)
    }

    private func waitForResponse(id targetID: Int) throws -> [String: Any] {
        while true {
            let message = try readMessage()
            if let id = (message["id"] as? NSNumber)?.intValue, id == targetID {
                return message
            }
        }
    }

    private func readMessage() throws -> [String: Any] {
        var header = Data()
        let separator = Data("\r\n\r\n".utf8)

        while Self.hasSuffix(header, separator) == false {
            guard let chunk = try outputHandle.read(upToCount: 1), chunk.isEmpty == false else {
                throw NSError(domain: "SourceKitLSPClient", code: 2)
            }
            header.append(chunk)
        }

        guard
            let headerString = String(data: header, encoding: .utf8),
            let contentLengthLine = headerString.split(separator: "\r\n").first(where: { $0.lowercased().hasPrefix("content-length:") }),
            let contentLength = Int(contentLengthLine.split(separator: ":", maxSplits: 1)[1].trimmingCharacters(in: .whitespaces))
        else {
            throw NSError(domain: "SourceKitLSPClient", code: 3)
        }

        let body = try readExactly(contentLength)
        guard let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw NSError(domain: "SourceKitLSPClient", code: 4)
        }
        return payload
    }

    private func readExactly(_ count: Int) throws -> Data {
        var data = Data()
        while data.count < count {
            let remaining = count - data.count
            guard let chunk = try outputHandle.read(upToCount: remaining), chunk.isEmpty == false else {
                throw NSError(domain: "SourceKitLSPClient", code: 5)
            }
            data.append(chunk)
        }
        return data
    }

    private static func compileCommand(
        for fileURL: URL,
        kind: ObjCFileKind,
        workspaceURL: URL,
        sdkPath: String
    ) -> [String: String] {
        let arguments = [
            "clang",
            "-x", kind.clangLanguage,
            "-fsyntax-only",
            "-isysroot", sdkPath,
            "-fmodules",
            "-fobjc-arc",
            "-I", workspaceURL.path,
            fileURL.path,
        ]

        return [
            "directory": workspaceURL.path,
            "file": fileURL.path,
            "command": arguments.map(shellEscape).joined(separator: " "),
        ]
    }

    private static func shellEscape(_ argument: String) -> String {
        guard argument.range(of: #"^[A-Za-z0-9_./-]+$"#, options: .regularExpression) != nil else {
            return argument
        }
        return "'\(argument.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func commandOutput(_ executable: String, arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = try FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "SourceKitLSPClient", code: 6)
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), string.isEmpty == false else {
            throw NSError(domain: "SourceKitLSPClient", code: 7)
        }
        return string
    }

    private static func lineStartOffsets(in source: String) -> [Int] {
        let string = source as NSString
        var starts: [Int] = [0]
        var location = 0

        while location < string.length {
            let lineRange = string.lineRange(for: NSRange(location: location, length: 0))
            let next = NSMaxRange(lineRange)
            if next < string.length {
                starts.append(next)
            }
            location = next
        }

        return starts
    }

    private static func hasSuffix(_ data: Data, _ suffix: Data) -> Bool {
        guard data.count >= suffix.count else { return false }
        return Data(data.suffix(suffix.count)) == suffix
    }
}
#endif
