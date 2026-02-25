import AppKit
import SwiftUI

struct StockTileView: View {
    let watched: WatchedStock
    let quote: StockQuote?
    let onRemove: (() -> Void)?
    let onUpdateLabel: ((String) -> Void)?

    @State private var isHovering = false
    @State private var showPopover = false
    @State private var hoverTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var direction: PriceDirection {
        quote?.direction ?? .flat
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isHovering ? Color.tileHoverBorder : .clear, lineWidth: 1)
                )

            Text(watched.stock.displayLabel)
                .font(.tileLabel)
                .foregroundStyle(tileTextColor)

            if let onRemove {
                ZStack {
                    AcceptFirstMouseButton(action: onRemove)

                    Image(systemName: "xmark")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 10, height: 10)
                        .background(Color.widgetBackground.opacity(0.8))
                        .clipShape(Circle())
                        .allowsHitTesting(false)
                }
                .frame(width: 10, height: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(1)
                .opacity(isHovering ? 1 : 0)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: isHovering)
            }
        }
        .frame(width: 28, height: 28)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            TilePopoverView(stock: watched.stock, quote: quote)
        }
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled else { return }
                    showPopover = true
                }
            } else {
                showPopover = false
            }
        }
        .contextMenu {
            if let onRemove {
                Button("Remove") { onRemove() }
                Divider()
            }
            if let onUpdateLabel {
                Button("Edit label...") {
                    let alert = NSAlert()
                    alert.messageText = "Edit label"
                    alert.informativeText = "Enter custom display text"
                    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
                    input.stringValue = watched.stock.customLabel ?? ""
                    input.placeholderString = String(watched.stock.name.prefix(2))
                    alert.accessoryView = input
                    alert.addButton(withTitle: "OK")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        onUpdateLabel(input.stringValue)
                    }
                }
            }
        }
        .accessibilityLabel("\(watched.stock.name), \(directionText)")
        .accessibilityValue(quote.map { "\($0.currentPrice)원, \($0.changeRate)%" } ?? "No data")
    }

    private var tileBackground: Color {
        switch direction {
        case .rise: return .tileRiseBackground
        case .fall: return .tileFallBackground
        case .flat: return .tileFlatBackground
        }
    }

    private var tileTextColor: Color {
        switch direction {
        case .rise: return .tileRiseText
        case .fall: return .tileFallText
        case .flat: return .tileFlatText
        }
    }

    private var directionText: String {
        switch direction {
        case .rise: return "up"
        case .fall: return "down"
        case .flat: return "flat"
        }
    }
}

// MARK: - AcceptFirstMouseButton

/// SwiftUI Button 대신 AppKit 레벨에서 클릭을 처리하는 NSViewRepresentable.
/// key window 여부와 무관하게 acceptsFirstMouse로 첫 번째 클릭을 직접 수신한다.
struct AcceptFirstMouseButton: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> ClickableNSView {
        let view = ClickableNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: ClickableNSView, context: Context) {
        nsView.action = action
    }

    class ClickableNSView: NSView {
        var action: (() -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            // super 미호출 — FirstMouseHostingView로 전파 방지
        }

        override func mouseUp(with event: NSEvent) {
            let pt = convert(event.locationInWindow, from: nil)
            if bounds.contains(pt) { action?() }
        }
    }
}
