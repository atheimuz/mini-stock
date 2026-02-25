import AppKit
import SwiftUI

private class StockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        window?.makeKey()
        super.mouseDown(with: event)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: StockPanel!
    private var store: StockStore!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = StockStore()

        let contentView = WidgetPanelView(store: store)

        panel = StockPanel(
            contentRect: NSRect(x: 0, y: 0, width: 232, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .normal
        panel.isFloatingPanel = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = NSColor(Color.widgetBackground)
        panel.isOpaque = false
        panel.hasShadow = true
        panel.acceptsMouseMovedEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.managed]
        panel.minSize = NSSize(width: 160, height: 200)
        let hostingView = FirstMouseHostingView(rootView: contentView)
        panel.contentView = hostingView

        // Restore position and size, or center
        let defaults = UserDefaults.standard
        let w = defaults.object(forKey: "window_w") as? CGFloat ?? 232
        let h = defaults.object(forKey: "window_h") as? CGFloat ?? 300
        if let x = defaults.object(forKey: "window_x") as? CGFloat,
           let y = defaults.object(forKey: "window_y") as? CGFloat {
            panel.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        } else {
            panel.setContentSize(NSSize(width: w, height: h))
            panel.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        let saveFrame = { [weak self] in
            guard let frame = self?.panel.frame else { return }
            UserDefaults.standard.set(frame.origin.x, forKey: "window_x")
            UserDefaults.standard.set(frame.origin.y, forKey: "window_y")
            UserDefaults.standard.set(frame.size.width, forKey: "window_w")
            UserDefaults.standard.set(frame.size.height, forKey: "window_h")
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { _ in saveFrame() }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: panel,
            queue: .main
        ) { _ in saveFrame() }


    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
