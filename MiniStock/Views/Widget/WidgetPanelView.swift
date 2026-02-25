import SwiftUI

struct WidgetPanelView: View {
    @Bindable var store: StockStore

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HeaderView(store: store)

                switch store.activeTab {
                case .stocks:
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
                case .balance:
                    if !store.isConfigured {
                        EmptyGridView(
                            message: "Setup required",
                            action: { store.showSettings = true }
                        )
                    } else {
                        BalanceView(store: store)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
            .padding(.top, 28)

            HStack(spacing: 4) {
                Slider(value: $store.widgetOpacity, in: 0.1...1.0, step: 0.05)
                    .tint(Color.tileRiseText)
                    .controlSize(.mini)
                    .frame(width: 56)

                Text("\(Int(store.widgetOpacity * 100))%")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.textSecondary)
                    .frame(width: 26, alignment: .trailing)
            }
            .padding(.top, 6)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.widgetBackground)
        .opacity(store.widgetOpacity)
        .overlay(alignment: .bottom) {
            if store.undoItem != nil {
                UndoToastView(store: store)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.undoItem != nil)
    }
}
