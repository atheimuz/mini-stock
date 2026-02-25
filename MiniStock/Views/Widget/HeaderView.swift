import SwiftUI

struct HeaderView: View {
    @Bindable var store: StockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("MONITOR")
                    .font(.widgetTitle)
                    .foregroundStyle(Color.textPrimary)
                    .tracking(2)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { Task { await store.refreshAll() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                            .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
                            .animation(
                                store.isRefreshing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: store.isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh")

                    Button(action: { store.showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                    .persistentPopover(isPresented: $store.showSettings, arrowEdge: .minY) {
                        SettingsPanelView(store: store)
                    }

                    Button(action: { store.showSearch = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add item")
                    .popover(isPresented: $store.showSearch, arrowEdge: .top) {
                        SearchPanelView(store: store)
                    }
                }
            }

            HStack(spacing: 4) {
                if let time = store.lastRefreshTime {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.hint)
                        .foregroundStyle(Color.textSecondary)
                }

                Circle()
                    .fill(indicatorColor)
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.bottom, 12)
    }

    private var indicatorColor: Color {
        if store.isRefreshing { return .indicatorActive }
        if store.hasError { return .indicatorError }
        return .textSecondary
    }
}
