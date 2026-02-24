import SwiftUI

struct WidgetPanelView: View {
    @Bindable var store: StockStore

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderView(store: store)

                if !store.isConfigured {
                    EmptyGridView(
                        message: "Setup required",
                        action: { store.showSettings = true }
                    )
                } else if store.watchedStocks.isEmpty {
                    EmptyGridView(
                        message: "Add items",
                        action: { store.showSearch = true }
                    )
                } else {
                    StockGridView(store: store)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 28)

            if store.undoItem != nil {
                UndoToastView(store: store)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.widgetBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.widgetBorder, lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: store.undoItem != nil)
    }
}
