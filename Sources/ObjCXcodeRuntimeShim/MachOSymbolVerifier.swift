#if os(macOS)
import Foundation
import MachOKit

enum MachOSymbolVerifier {
    static func verify(manifest: XcodePrivateFrameworkManifest) throws {
        for framework in manifest.frameworks where framework.requiredSymbols.isEmpty == false {
            let url = URL(fileURLWithPath: framework.path)
            let machOFile = try MachOKit.loadFromFile(url: url)

            let images: [MachOFile]
            switch machOFile {
            case let .machO(machO):
                images = [machO]
            case let .fat(fatFile):
                images = try fatFile.machOFiles()
            }

            for symbol in framework.requiredSymbols {
                let found = images.contains { image in
                    if image.symbols(named: symbol, mangled: false).isEmpty == false {
                        return true
                    }
                    return image.exportedSymbols.contains { $0.name == symbol }
                }

                if found == false {
                    throw MachOSymbolVerifierError.missingSymbol(symbol, framework.path)
                }
            }
        }
    }
}

private enum MachOSymbolVerifierError: LocalizedError {
    case missingSymbol(String, String)

    var errorDescription: String? {
        switch self {
        case let .missingSymbol(symbol, path):
            "Missing required symbol \(symbol) in \(path)"
        }
    }
}
#endif
