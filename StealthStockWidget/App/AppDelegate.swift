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
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
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
        panel.collectionBehavior = [.managed]
        let hostingView = FirstMouseHostingView(rootView: contentView)
        panel.contentView = hostingView

        // Restore position or center
        if let x = UserDefaults.standard.object(forKey: "window_x") as? CGFloat,
           let y = UserDefaults.standard.object(forKey: "window_y") as? CGFloat {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }

        panel.orderFront(nil)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            guard let origin = self?.panel.frame.origin else { return }
            UserDefaults.standard.set(origin.x, forKey: "window_x")
            UserDefaults.standard.set(origin.y, forKey: "window_y")
        }

        // 스페이스 전환 후 돌아올 때 위젯이 맨 뒤로 가지 않도록
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.panel.orderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
