import SwiftUI

struct StockGridView: View {
    @Bindable var store: StockStore

    private let columns = [GridItem(.adaptive(minimum: 28), spacing: 4)]

    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(store.displayStocks) { watched in
                    let isPortfolio = store.isPortfolioStock(code: watched.stock.code)
                    StockTileView(
                        watched: watched,
                        quote: store.quotes[watched.stock.code],
                        onRemove: isPortfolio ? nil : { store.removeStock(code: watched.stock.code) },
                        onUpdateLabel: isPortfolio ? nil : { label in store.updateLabel(code: watched.stock.code, label: label) }
                    )
                    .draggable(watched.stock.code)
                    .dropDestination(for: String.self) { codes, _ in
                        guard !isPortfolio,
                              let code = codes.first,
                              let from = store.watchedStocks.firstIndex(where: { $0.stock.code == code }),
                              let to = store.watchedStocks.firstIndex(where: { $0.stock.code == watched.stock.code }),
                              from != to
                        else { return false }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.moveStock(from: IndexSet(integer: from), to: to > from ? to + 1 : to)
                        }
                        return true
                    }
                }
            }

            if store.showHoverHint {
                HoverHintView {
                    withAnimation { store.showHoverHint = false }
                }
            }
        }
    }
}

struct HoverHintView: View {
    let onDismiss: () -> Void

    @State private var opacity: Double = 1.0

    var body: some View {
        Text("Hover over a tile for details")
            .font(.hint)
            .foregroundStyle(Color.tileRiseText.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.tileRiseText.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .opacity(opacity)
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
                    try? await Task.sleep(for: .milliseconds(500))
                    onDismiss()
                }
            }
    }
}
