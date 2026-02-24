import SwiftUI

struct StockTileView: View {
    let watched: WatchedStock
    let quote: StockQuote?
    let onRemove: () -> Void
    let onUpdateLabel: (String) -> Void

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

            if isHovering {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 10, height: 10)
                        .background(Color.widgetBackground.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(1)
                .transition(.opacity)
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
            Button("Remove") { onRemove() }
            Divider()
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
