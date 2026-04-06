#if os(macOS)
import AppKit
import ObjCXcodeRuntimeShim
import SwiftUI

@available(iOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(tvOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(watchOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
@available(visionOS, unavailable, message: "ObjCSyntaxInk is available on macOS only.")
public struct ObjCSourceEditorView: NSViewControllerRepresentable {
    public let source: String
    public let theme: ObjCTheme
    public let fileName: String

    public init(source: String, theme: ObjCTheme = .default, fileName: String) {
        self.source = source
        self.theme = theme
        self.fileName = fileName
    }

    public func makeNSViewController(context: Context) -> ObjCXcodeSourceEditorController {
        ObjCXcodeSourceEditorController(
            source: source,
            themeDisplayName: theme.displayName,
            fileName: fileName,
            previewMode: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        )
    }

    public func updateNSViewController(_ controller: ObjCXcodeSourceEditorController, context: Context) {
        controller.update(
            source: source,
            themeDisplayName: theme.displayName,
            fileName: fileName,
            previewMode: ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        )
    }
}

public final class ObjCXcodeSourceEditorController: NSViewController {
    private var source: String
    private var themeDisplayName: String
    private var fileName: String
    private var previewMode: Bool
    private var hostView: NSView?
    private var retiredHostViews: [NSView] = []

    init(source: String, themeDisplayName: String, fileName: String, previewMode: Bool) {
        self.source = source
        self.themeDisplayName = themeDisplayName
        self.fileName = fileName
        self.previewMode = previewMode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public override func loadView() {
        self.view = NSView(frame: .zero)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        installOrUpdateHostView()
    }

    func update(source: String, themeDisplayName: String, fileName: String, previewMode: Bool) {
        let didChange = self.source != source
            || self.themeDisplayName != themeDisplayName
            || self.fileName != fileName
            || self.previewMode != previewMode

        if didChange == false {
            if let hostView {
                ObjCXcodeRuntimeShim.refreshEditorHostView(hostView, active: false)
            }
            return
        }

        self.source = source
        self.themeDisplayName = themeDisplayName
        self.fileName = fileName
        self.previewMode = previewMode

        if let hostView {
            hostView.removeFromSuperview()
            retiredHostViews.append(hostView)
            self.hostView = nil
        }

        installOrUpdateHostView()
    }

    private func installOrUpdateHostView() {
        if let hostView {
            ObjCXcodeRuntimeShim.refreshEditorHostView(hostView, active: false)
            return
        }

        do {
            let hostView = try ObjCXcodeRuntimeShim.makeEditorHostView(
                source: source,
                fileName: fileName,
                themeDisplayName: themeDisplayName,
                previewMode: previewMode
            )
            hostView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostView)
            NSLayoutConstraint.activate([
                hostView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostView.topAnchor.constraint(equalTo: view.topAnchor),
                hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            self.hostView = hostView
            ObjCXcodeRuntimeShim.refreshEditorHostView(hostView, active: false)
        } catch {
            preconditionFailure("Failed to create Xcode private ObjC editor view: \(error.localizedDescription)")
        }
    }
}
#endif
