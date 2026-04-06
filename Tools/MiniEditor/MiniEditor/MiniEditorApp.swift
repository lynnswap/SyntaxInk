//
//  MiniEditorApp.swift
//  MiniEditor
//
//  Created by Kazuki Nakashima on 2026/04/05.
//

import AppKit
import SwiftUI

final class MiniEditorApplication: NSObject, NSApplicationDelegate {
    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hostingController = NSHostingController(rootView: ContentView())

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "MiniEditor"
        window.center()
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.windowController = controller
        controller.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MiniEditorApp: App {
    @NSApplicationDelegateAdaptor(MiniEditorApplication.self) private var application

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
