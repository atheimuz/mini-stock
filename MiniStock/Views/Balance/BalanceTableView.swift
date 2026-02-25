import SwiftUI

struct BalanceTableView: View {
    let holdings: [BalanceHolding]

    var body: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider().background(Color.widgetBorder)

            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(holdings) { holding in
                            BalanceRowView(holding: holding)
                            Divider().background(Color.widgetBorder)
                        }
                    }
                }

                // Fade-out gradient
                LinearGradient(
                    colors: [Color.widgetBackground.opacity(0), Color.widgetBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                .allowsHitTesting(false)
            }
        }
    }

    private var tableHeader: some View {
        VStack(spacing: 1) {
            HStack(spacing: 0) {
                Text("종목명")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("평가손익")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("보유")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("매입단가")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            HStack(spacing: 0) {
                Text("")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("수익률")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("평가금액")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("현재가")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .font(.hint)
        .foregroundStyle(Color.textSecondary)
        .padding(.vertical, 4)
    }
}
