import SwiftUI

struct BalanceView: View {
    @Bindable var store: StockStore

    var body: some View {
        if !store.hasAccountNumber {
            emptyAccountView
        } else if store.isBalanceRefreshing && store.balanceHoldings.isEmpty {
            skeletonView
        } else if store.balanceHasError && store.balanceHoldings.isEmpty {
            errorView
        } else if store.balanceHoldings.isEmpty && store.balanceSummary == nil {
            emptyHoldingsView
        } else {
            VStack(spacing: 8) {
                BalanceSummaryTile(summary: store.balanceSummary ?? .zero)
                BalanceTableView(holdings: store.balanceHoldings)
            }
        }
    }

    // MARK: - Empty States

    private var emptyAccountView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("계좌번호를 설정해주세요")
                .font(.popoverName)
                .foregroundStyle(Color.textSecondary)
            Text("설정에서 계좌번호(8자리)를 입력하면\n보유 종목을 확인할 수 있습니다")
                .font(.hint)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: { store.showSettings = true }) {
                Text("설정 열기")
                    .font(.buttonFont)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.tileFlatBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("잔고를 불러올 수 없습니다")
                .font(.popoverName)
                .foregroundStyle(Color.textSecondary)
            Text("새로고침 버튼으로 다시 시도해주세요")
                .font(.hint)
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyHoldingsView: some View {
        VStack(spacing: 8) {
            BalanceSummaryTile(summary: .zero)
            Spacer()
            Text("보유 종목이 없습니다")
                .font(.popoverName)
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skeleton

    private var skeletonView: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.tileFlatBackground)
                .frame(height: 48)
                .shimmer()

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.tileFlatBackground)
                    .frame(height: 36)
                    .shimmer()
            }
            Spacer()
        }
    }
}

// MARK: - Shimmer Effect

private struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
