import AppKit
import SwiftUI

/// 앱 전환 시에도 닫히지 않는 popover modifier.
/// macOS 기본 `.popover`는 transient 동작으로 포커스를 잃으면 자동 닫힘.
/// 이 래퍼는 `NSPopover.behavior = .applicationDefined`를 사용하여 이를 방지.
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

    class Coordinator: NSObject, NSPopoverDelegate {
        weak var anchorView: NSView?
        var arrowEdge: NSRectEdge = .minY
        var contentBuilder: (() -> PopoverContent)?
        private var popover: NSPopover?
        private var isClosing = false
        @Binding var isPresented: Bool

        init(isPresented: Binding<Bool>) {
            _isPresented = isPresented
        }

        func showIfNeeded() {
            guard popover == nil, !isClosing,
                  let anchor = anchorView, anchor.window != nil,
                  let content = contentBuilder else { return }

            let p = NSPopover()
            p.behavior = .applicationDefined
            p.contentViewController = NSHostingController(rootView: content())
            p.delegate = self
            popover = p

            DispatchQueue.main.async { [weak self] in
                guard let self, let anchor = self.anchorView, anchor.window != nil else { return }
                p.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: self.arrowEdge)
            }
        }

        func closeIfNeeded() {
            guard let p = popover, p.isShown else {
                popover = nil
                return
            }
            isClosing = true
            p.performClose(nil)
        }

        func popoverDidClose(_ notification: Notification) {
            popover = nil
            isClosing = false
            if isPresented {
                isPresented = false
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
