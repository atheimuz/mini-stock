import AppKit
import SwiftUI

/// 앱 전환 시에도 닫히지 않는 popover modifier.
/// NSPopover 대신 borderless NSPanel을 사용하여 시스템 크롬(보더) 없이 표시.
struct PersistentPopover<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let arrowEdge: NSRectEdge
    @ViewBuilder let content: () -> PopoverContent

    func body(content: Content) -> some View {
        content
            .background(
                PersistentPopoverRepresentable(
                    isPresented: $isPresented,
                    arrowEdge: arrowEdge,
                    popoverContent: self.content
                )
            )
    }
}

private struct PersistentPopoverRepresentable<PopoverContent: View>: NSViewRepresentable {
    @Binding var isPresented: Bool
    let arrowEdge: NSRectEdge
    let popoverContent: () -> PopoverContent

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.anchorView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.anchorView = nsView
        context.coordinator.arrowEdge = arrowEdge
        context.coordinator.contentBuilder = popoverContent

        if isPresented {
            context.coordinator.showIfNeeded()
        } else {
            context.coordinator.closeIfNeeded()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    class Coordinator: NSObject {
        weak var anchorView: NSView?
        var arrowEdge: NSRectEdge = .minY
        var contentBuilder: (() -> PopoverContent)?
        private var panel: NSPanel?
        private var monitor: Any?
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func showIfNeeded() {
            guard panel == nil,
                  let anchor = anchorView, let parentWindow = anchor.window,
                  let content = contentBuilder else { return }

            let hostingView = NSHostingView(rootView: content())
            let fittingSize = hostingView.fittingSize

            let p = NSPanel(
                contentRect: NSRect(origin: .zero, size: fittingSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: true
            )
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.level = .popUpMenu
            p.isMovable = false

            let container = NSView(frame: NSRect(origin: .zero, size: fittingSize))
            container.wantsLayer = true
            container.layer?.backgroundColor = NSColor(Color.widgetBackground).cgColor
            container.layer?.cornerRadius = 8
            container.layer?.masksToBounds = true

            hostingView.frame = container.bounds
            hostingView.autoresizingMask = [.width, .height]
            container.addSubview(hostingView)

            p.contentView = container
            panel = p

            let anchorRect = anchor.convert(anchor.bounds, to: nil)
            let screenRect = parentWindow.convertToScreen(anchorRect)

            let origin: NSPoint
            switch arrowEdge {
            case .minY:
                origin = NSPoint(
                    x: screenRect.midX - fittingSize.width / 2,
                    y: screenRect.minY - fittingSize.height - 4
                )
            case .maxY:
                origin = NSPoint(
                    x: screenRect.midX - fittingSize.width / 2,
                    y: screenRect.maxY + 4
                )
            case .minX:
                origin = NSPoint(
                    x: screenRect.minX - fittingSize.width - 4,
                    y: screenRect.midY - fittingSize.height / 2
                )
            case .maxX:
                origin = NSPoint(
                    x: screenRect.maxX + 4,
                    y: screenRect.midY - fittingSize.height / 2
                )
            default:
                origin = NSPoint(
                    x: screenRect.midX - fittingSize.width / 2,
                    y: screenRect.minY - fittingSize.height - 4
                )
            }

            p.setFrameOrigin(origin)
            parentWindow.addChildWindow(p, ordered: .above)

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                guard let self, let panel = self.panel else { return event }
                let loc = event.locationInWindow
                if event.window == panel {
                    return event
                }
                // 패널 좌표로 변환하여 클릭이 패널 밖인지 확인
                let panelLoc = panel.convertPoint(fromScreen: NSEvent.mouseLocation)
                if !panel.contentView!.bounds.contains(panelLoc) {
                    self.close()
                }
                return event
            }
        }

        func closeIfNeeded() {
            close()
        }

        private func close() {
            if let m = monitor {
                NSEvent.removeMonitor(m)
                monitor = nil
            }
            if let p = panel {
                p.parent?.removeChildWindow(p)
                p.orderOut(nil)
                panel = nil
            }
            if isPresented {
                isPresented = false
            }
        }

        deinit {
            if let m = monitor {
                NSEvent.removeMonitor(m)
            }
            if let p = panel {
                p.parent?.removeChildWindow(p)
                p.orderOut(nil)
            }
        }
    }
}

extension View {
    func persistentPopover<Content: View>(
        isPresented: Binding<Bool>,
        arrowEdge: NSRectEdge = .maxY,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(PersistentPopover(isPresented: isPresented, arrowEdge: arrowEdge, content: content))
    }
}
