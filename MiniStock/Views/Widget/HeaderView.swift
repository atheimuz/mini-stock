import SwiftUI

struct HeaderView: View {
    @Bindable var store: StockStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                segmentControl

                Spacer()

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
            }

            HStack(spacing: 4) {
                if let time = currentRefreshTime {
                    Text(time, format: .dateTime.hour().minute())
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                }

                Circle()
                    .fill(indicatorColor)
                    .frame(width: 5, height: 5)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            switch store.activeTab {
                            case .stocks: await store.refreshAll()
                            case .balance: await store.refreshBalance()
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.textSecondary)
                            .rotationEffect(.degrees(currentIsRefreshing ? 360 : 0))
                            .animation(
                                currentIsRefreshing
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: currentIsRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh")

                    if store.activeTab == .stocks {
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
            }

        }
        .padding(.bottom, 12)
    }

    // MARK: - Segment Control

    private var segmentControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "종목", tab: .stocks)
            segmentButton(title: "잔고", tab: .balance)
        }
        .padding(2)
        .background(Color.tileFlatBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .contain)
    }

    private func segmentButton(title: String, tab: AppTab) -> some View {
        let isActive = store.activeTab == tab
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                store.switchTab(tab)
            }
        }) {
            Text(title)
                .font(.widgetTitle)
                .tracking(1)
                .foregroundStyle(isActive ? Color.textPrimary : Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Color.segmentActiveBackground : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isActive ? "selected" : "unselected")
    }

    // MARK: - Tab-dependent State

    private var currentIsRefreshing: Bool {
        switch store.activeTab {
        case .stocks: store.isRefreshing
        case .balance: store.isBalanceRefreshing
        }
    }

    private var currentRefreshTime: Date? {
        switch store.activeTab {
        case .stocks: store.lastRefreshTime
        case .balance: store.balanceLastRefreshTime
        }
    }

    private var indicatorColor: Color {
        switch store.activeTab {
        case .stocks:
            if store.isRefreshing { return .indicatorActive }
            if store.hasError { return .indicatorError }
        case .balance:
            if store.isBalanceRefreshing { return .indicatorActive }
            if store.balanceHasError { return .indicatorError }
        }
        return .textSecondary
    }
}
