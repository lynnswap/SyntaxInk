#if DEBUG && os(macOS)
import SyntaxInk
import SwiftUI

struct ObjCPlayground: View {
    var code: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let syntaxHighlighter = ObjCSyntaxHighlighter(theme: colorScheme == .light ? .default : .defaultDark)
        let attributedString = syntaxHighlighter.highlight(code)

        ScrollView {
            Text(attributedString)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(colorScheme == .light ? Color.xcodeBackgroundDefaultColor : .xcodeBackgroundDefaultDarkColor)
#if os(visionOS)
        .glassBackgroundEffect()
#endif
    }
}

#Preview("Objective-C Header") {
    ObjCPlayground(code: objcHeaderSample)
        .frame(width:1000,height:400)
}

#Preview("Objective-C Implementation") {
    ObjCPlayground(code: objcImplementationSample)
        .frame(width:1000,height:400)
}
#endif
