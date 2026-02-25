import AppKit
import SwiftUI

private class StockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    private weak var firstMouseTarget: NSView?

    override func sendEvent(_ event: NSEvent) {
        // acceptsFirstMouse=true인 뷰(X버튼)는 항상 직접 dispatch.
        // macOS가 sendEvent 호출 전에 window를 key로 만들기 때문에
        // isKeyWindow 체크 없이 항상 처리해야 첫 클릭이 작동함.
        if event.type == .leftMouseDown {
            if let contentView = contentView, let superview = contentView.superview {
                let pt = superview.convert(event.locationInWindow, from: nil)
                if let hitView = contentView.hitTest(pt) as? AcceptFirstMouseButton.ClickableNSView {
                    firstMouseTarget = hitView
                    hitView.mouseDown(with: event)
                    return
                }
            }
        }

        if event.type == .leftMouseUp, let target = firstMouseTarget {
            firstMouseTarget = nil
            target.mouseUp(with: event)
            return
        }

        super.sendEvent(event)
    }
}

private class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // NSHostingView는 hitTest를 오버라이드하여 SwiftUI 내부로 이벤트를 라우팅함.
        // acceptsFirstMouse=true인 ClickableNSView를 직접 반환하여 이 라우팅을 우회.
        let localPoint = convert(point, from: superview)
        if let firstMouseView = findFirstMouseView(in: self, at: localPoint) {
            return firstMouseView
        }
        return super.hitTest(point)
    }

    private func findFirstMouseView(in parent: NSView, at point: NSPoint) -> NSView? {
        for subview in parent.subviews.reversed() {
            let localPoint = parent.convert(point, to: subview)
            guard !subview.isHidden, subview.bounds.contains(localPoint) else { continue }
            if let found = findFirstMouseView(in: subview, at: localPoint) {
                return found
            }
            if subview !== self, subview.acceptsFirstMouse(for: nil) {
                return subview
            }
        }
        return nil
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
